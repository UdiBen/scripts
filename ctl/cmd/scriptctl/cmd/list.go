package cmd

import (
	"fmt"
	"os"
	"sort"
	"strings"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "List all available scripts",
	Long:  `Lists all executable scripts found in the scripts directory.`,
	RunE: func(cmd *cobra.Command, args []string) error {
		scripts, err := discoverScripts()
		if err != nil {
			return fmt.Errorf("error discovering scripts: %w", err)
		}

		if len(scripts) == 0 {
			fmt.Printf("No scripts found in %s\n", scriptsDir)
			fmt.Printf("Add executable scripts matching these patterns: %s\n", strings.Join(scriptPatterns, ", "))
			return nil
		}

		// Sort scripts by name
		sort.Slice(scripts, func(i, j int) bool {
			return scripts[i].Name < scripts[j].Name
		})

		fmt.Printf("Available scripts in %s:\n\n", scriptsDir)
		for _, script := range scripts {
			// Check if executable
			info, _ := os.Stat(script.Path)
			execMark := " "
			if isExecutable(info) {
				execMark = "*"
			}

			// Format: [*] name - description
			if script.Description != "" {
				fmt.Printf("  %s %-20s - %s\n", execMark, script.Name, script.Description)
			} else {
				fmt.Printf("  %s %s\n", execMark, script.Name)
			}
		}
		fmt.Println()
		fmt.Println("Usage: scriptctl <script-name> [args...]")
		fmt.Println("  * = executable")

		return nil
	},
}

func init() {
	rootCmd.AddCommand(listCmd)
}
