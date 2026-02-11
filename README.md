# fancy-header.nvim

A Neovim plugin that parses and visually styles the standard 42 School C header using native semantic highlights, featuring customizable colors and smooth vertical gradients.

## Features

* **Native Highlights**: Applies colors directly to your existing characters using `hl_group` (no glitchy virtual text overlays or overlapping git signs).
* **Smart Parsing**: Dynamically finds the gap between your text (author, filename) and the 42 ASCII logo to apply split coloring flawlessly on the same line.
* **Gradient Engine**: Automatically calculates intermediate hex codes to create a smooth, 7-line vertical gradient across the 42 logo.
* **Real-time Updates**: Refreshes instantly when you open a file, leave insert mode, or change text.

## Installation

To install with [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "Stefanistkuhl/fancy-header.nvim",
    ft = { "c", "cpp", "h" },

    -- Configuration (Rosé Pine example)
    opts = {
        colors = {
            box      = { fg = "#6e6a86" },
            filename = { fg = "#f6c177", bold = true },
            author   = { fg = "#9ccfd8" },
            date     = { fg = "#c4a7e7" },

            -- Use 'start' and 'end_' to create a vertical gradient
            logo_42  = { start = "#eb6f92", end_ = "#31748f" }, 
        },
    },

    keys = {
        { "<leader>4h", "<cmd>HeaderToggle<cr>", desc = "Toggle 42 Header" },
    },
}

```

## Usage

Once installed, the plugin works out of the box whenever you open a `.c` or `.h` file containing a standard 42 header.

* **Automatic**: The header is styled instantly upon opening the buffer. It updates automatically when you modify the text or save the file.
* **Manual**: Press `<leader>4h` (or your configured keybinding) to toggle the visual styling on or off.
* **Command**: Run `:HeaderToggle` to toggle the styling via command mode.

## Configuration

You can pass the following options inside the `colors` table in `opts`:

| Option | Type | Default | Description |
| --- | --- | --- | --- |
| `colors.box` | `table` | `{ fg = "#6e6a86" }` | Defines the highlight for the `/*` and `*/` borders. |
| `colors.filename` | `table` | `{ fg = "#f6c177", bold = true }` | Highlight for the filename text. |
| `colors.author` | `table` | `{ fg = "#9ccfd8" }` | Highlight for the `By: name <email>` text. |
| `colors.date` | `table` | `{ fg = "#c4a7e7" }` | Highlight for the `Created:` and `Updated:` text. |
| `colors.logo_42` | `table` | `{ start = "#eb6f92", end_ = "#31748f" }` | Pass `start` and `end_` hex codes to generate a vertical gradient. Pass `fg = "#HEX"` instead for a solid color. |

## Requirements

* **Neovim 0.10+** (Utilizes modern `nvim_set_hl` and `nvim_buf_set_extmark` APIs).
* **A Standard 42 Header**: The file must begin with a correctly formatted 80-column 42 header (e.g., generated via the standard 42 plugin).
