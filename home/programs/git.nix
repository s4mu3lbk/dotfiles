let name = "Samuel Bekele";
in {
  programs.git = {
    settings = {
      user.email = "s4mu3lbk@gmail.com";
      user.name = name;
      color.ui = true;
      core.editor = "nvim";
      credential.helper = "store";
      github.user = "s4mu3lbk";
      push.autoSetupRemote = true;
    };
    enable = true;
  };
}
