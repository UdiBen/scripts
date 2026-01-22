package cmd

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/mitchellh/go-homedir"
	"github.com/spf13/cobra"
)

var (
	scriptsDir     string
	scriptPatterns = []string{"*.sh", "*.py", "*.rb", "*.js", "*.ts"}
)

// rootCmd represents the base command
var rootCmd = &cobra.Command{
	Use:   "scriptctl",
	Short: "A CLI tool to manage and run your custom scripts",
	Long: `scriptctl helps you organize and execute custom scripts from ~/scripts.

Usage examples:
  scriptctl list              # List all available scripts
  scriptctl backup            # Run backup.sh (or backup.py, etc.)
  scriptctl backup --verbose  # Run backup.sh with --verbose flag`,
	SilenceErrors:         true,
	SilenceUsage:          true,
	DisableFlagParsing:    false,
	DisableFlagsInUseLine: true,
	Run: func(cmd *cobra.Command, args []string) {
		if err := cmd.Help(); err != nil {
			fmt.Fprintf(os.Stderr, "Error showing help: %s\n", err)
		}
	},
}

// Execute runs the root command
func Execute() {
	// Initialize config early so we have scriptsDir available
	initConfig()

	if err := rootCmd.Execute(); err != nil {
		// Check if it's an unknown command error
		if isUnknownCommandError(err) && len(os.Args) > 1 {
			// Try to execute as a script
			scriptName := os.Args[1]
			scriptArgs := os.Args[2:]

			scriptPath, findErr := findScript(scriptName)
			if findErr != nil {
				fmt.Fprintf(os.Stderr, "Error: unknown command '%s' and no matching script found in %s\n", scriptName, scriptsDir)
				fmt.Fprintf(os.Stderr, "Run 'scriptctl list' to see available scripts\n")
				os.Exit(1)
			}

			if execErr := executeScript(scriptPath, scriptArgs); execErr != nil {
				fmt.Fprintf(os.Stderr, "Error executing script: %s\n", execErr)
				os.Exit(1)
			}
			return
		}

		fmt.Fprintf(os.Stderr, "Error: %s\n", err)
		os.Exit(1)
	}
}

// isUnknownCommandError checks if the error is an unknown command error
func isUnknownCommandError(err error) bool {
	if err == nil {
		return false
	}
	return strings.Contains(err.Error(), "unknown command")
}

func init() {
	cobra.OnInitialize(initConfig)
	rootCmd.PersistentFlags().StringVar(&scriptsDir, "scripts-dir", "", "directory containing scripts (default: ~/scripts)")
}

func initConfig() {
	if scriptsDir == "" {
		home, err := homedir.Dir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error finding home directory: %s\n", err)
			os.Exit(1)
		}
		scriptsDir = filepath.Join(home, "scripts")
	}

	// Expand ~ if present
	if strings.HasPrefix(scriptsDir, "~") {
		home, _ := homedir.Dir()
		scriptsDir = filepath.Join(home, scriptsDir[1:])
	}

	// Ensure scripts directory exists
	if _, err := os.Stat(scriptsDir); os.IsNotExist(err) {
		fmt.Fprintf(os.Stderr, "Scripts directory does not exist: %s\n", scriptsDir)
		fmt.Fprintf(os.Stderr, "Create it with: mkdir -p %s\n", scriptsDir)
		os.Exit(1)
	}
}

// findScript looks for a script matching the given name with any supported extension
func findScript(name string) (string, error) {
	// First, check if the exact name exists (no extension)
	exactPath := filepath.Join(scriptsDir, name)
	if info, err := os.Stat(exactPath); err == nil && !info.IsDir() {
		return exactPath, nil
	}

	// Try each pattern (with extension)
	for _, pattern := range scriptPatterns {
		ext := strings.TrimPrefix(pattern, "*")
		scriptPath := filepath.Join(scriptsDir, name+ext)
		if info, err := os.Stat(scriptPath); err == nil && !info.IsDir() {
			return scriptPath, nil
		}
	}

	return "", fmt.Errorf("script not found")
}

// isExecutable checks if a file has executable permissions
func isExecutable(info os.FileInfo) bool {
	return info.Mode()&0111 != 0
}

// executeScript runs the script with the given arguments
func executeScript(scriptPath string, args []string) error {
	cmd := exec.Command(scriptPath, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin

	return cmd.Run()
}

// extractDescription reads the script file and extracts the description from comments
func extractDescription(scriptPath string) string {
	file, err := os.Open(scriptPath)
	if err != nil {
		return ""
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineNum := 0
	for scanner.Scan() {
		lineNum++
		line := strings.TrimSpace(scanner.Text())

		// Skip shebang
		if lineNum == 1 && strings.HasPrefix(line, "#!") {
			continue
		}

		// Stop after first 20 lines
		if lineNum > 20 {
			break
		}

		// Look for description patterns
		// Supports: # Description: ..., # @description ..., // Description: ...
		for _, prefix := range []string{"# Description:", "# @description", "// Description:", "// @description"} {
			if strings.HasPrefix(line, prefix) {
				desc := strings.TrimSpace(strings.TrimPrefix(line, prefix))
				return strings.TrimPrefix(desc, ":")
			}
		}
	}

	return ""
}

// ScriptInfo holds information about a discovered script
type ScriptInfo struct {
	Path        string
	Name        string
	Extension   string
	Description string
}

// discoverScripts finds all scripts matching the patterns
func discoverScripts() ([]ScriptInfo, error) {
	scriptsMap := make(map[string]bool)
	var scripts []ScriptInfo

	// First, find scripts with known extensions
	for _, pattern := range scriptPatterns {
		matches, err := filepath.Glob(filepath.Join(scriptsDir, pattern))
		if err != nil {
			return nil, err
		}

		for _, match := range matches {
			info, err := os.Stat(match)
			if err != nil {
				continue
			}
			if info.IsDir() {
				continue
			}

			// Get base name without extension for deduplication
			baseName := strings.TrimSuffix(filepath.Base(match), filepath.Ext(match))
			if !scriptsMap[baseName] {
				scriptsMap[baseName] = true
				scripts = append(scripts, ScriptInfo{
					Path:        match,
					Name:        baseName,
					Extension:   filepath.Ext(match),
					Description: extractDescription(match),
				})
			}
		}
	}

	// Also find executable files without extensions
	entries, err := os.ReadDir(scriptsDir)
	if err != nil {
		return nil, err
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		name := entry.Name()
		// Skip if it has a known extension (already processed)
		ext := filepath.Ext(name)
		if ext != "" {
			hasKnownExt := false
			for _, pattern := range scriptPatterns {
				if strings.TrimPrefix(pattern, "*") == ext {
					hasKnownExt = true
					break
				}
			}
			if hasKnownExt {
				continue
			}
		}

		// Check if executable
		fullPath := filepath.Join(scriptsDir, name)
		info, err := os.Stat(fullPath)
		if err != nil {
			continue
		}

		if isExecutable(info) && !scriptsMap[name] {
			scriptsMap[name] = true
			scripts = append(scripts, ScriptInfo{
				Path:        fullPath,
				Name:        name,
				Extension:   "",
				Description: extractDescription(fullPath),
			})
		}
	}

	return scripts, nil
}
