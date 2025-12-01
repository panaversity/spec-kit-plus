{ pkgs, ... }: {
  packages = [ 
    pkgs.python311
    pkgs.uv
  ];
  idx.workspace.onCreate = {
    install = "pip install mcp[cli]";
  };
}
