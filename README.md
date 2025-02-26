# AbstractFramework

**AbstractFramework** is a minimalist World of Warcraft addon framework for fast widget creation.  
It's easy to use and ensures pixel-perfect precision, making it ideal for developers seeking a clean and efficient interface.

## Screenshot

![demo](https://raw.githubusercontent.com/enderneko/ImagePosts/main/1/af_demo.png)

Demo: `/abstract` or `/afw` or `/af`

## VS Code

1. Clone this repository to your local computer.
2. Add the repository directory to your system environment variables (e.g., `AF_HOME`).
3. Install the Lua extension ([sumneko.lua](https://marketplace.visualstudio.com/items?itemName=sumneko.lua)).
4. In your workspace's settings.json, add the following:

    ```json
    "Lua.workspace.library": [
        "${env:AF_HOME}"
    ]
    ```

5. Wherever you use AF, declare the type with:

    ```lua
    ---@type AbstractFramework
    local AF = _G.AbstractFramework
    ```
