# AbstractFramework

[![GitHub commit activity](https://img.shields.io/github/commit-activity/m/enderneko/AbstractFramework)](https://github.com/enderneko/AbstractFramework/commits/master)
[![last commit](https://img.shields.io/github/last-commit/enderneko/AbstractFramework)](https://github.com/enderneko/AbstractFramework/commits/master)
![wakatime](https://wakatime.com/badge/user/b2ffce60-8269-440f-81a0-7316f36a6085/project/3776f414-881d-4242-a1ed-2e4938c18d1b.svg)

**AbstractFramework** is a minimalist World of Warcraft addon framework for fast widget creation.  
It's easy to use and ensures pixel-perfect precision, making it ideal for developers seeking a clean and efficient interface.

## Screenshot

![demo](https://raw.githubusercontent.com/enderneko/ImagePosts/main/1/af_demo.png)

Demo: `/abstract` or `/afw` or `/af`

## VS Code

1. Clone this repository to your local computer or install the addon directly.
2. Add the `AbstractFramework` directory to your system environment variables (e.g., `AF_HOME`).
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
