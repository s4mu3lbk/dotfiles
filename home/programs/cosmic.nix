{
  xdg.configFile."cosmic/com.system76.CosmicSettings.Shortcuts/v1/custom".text = ''
    {
        (
            modifiers: [
                Super,
                Shift,
            ],
            key: "Up",
        ): Focus(Up),
        (
            modifiers: [
                Super,
                Shift,
            ],
            key: "Right",
        ): Focus(Right),
        (
            modifiers: [
                Ctrl,
                Alt,
            ],
            key: "Right",
        ): NextWorkspace,
        (
            modifiers: [
                Super,
            ],
            key: "Up",
        ): Move(Up),
        (
            modifiers: [
                Super,
            ],
            key: "Left",
        ): Move(Left),
        (
            modifiers: [
                Super,
            ],
            key: "Right",
        ): Move(Right),
        (
            modifiers: [
                Ctrl,
                Alt,
                Shift,
            ],
            key: "Left",
        ): MoveToPreviousWorkspace,
        (
            modifiers: [
                Super,
                Shift,
            ],
            key: "Left",
        ): Focus(Left),
        (
            modifiers: [
                Super,
            ],
            key: "Down",
        ): Move(Down),
        (
            modifiers: [
                Super,
                Shift,
            ],
            key: "Down",
        ): Focus(Down),
        (
            modifiers: [
                Ctrl,
                Alt,
            ],
            key: "Left",
        ): PreviousWorkspace,
        (
            modifiers: [
                Ctrl,
                Alt,
                Shift,
            ],
            key: "Right",
        ): MoveToNextWorkspace,
        (
            modifiers: [
                Super,
            ],
            key: "t",
        ): Spawn("cosmic-vimium --toggle"),
        (
            modifiers: [
                Super,
            ],
            key: "v",
        ): Spawn("viscus trigger"),
    }
  '';
}
