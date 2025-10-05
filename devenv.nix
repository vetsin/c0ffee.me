{ pkgs, lib, config, inputs, ... }:

{
  packages = [ pkgs.git ];
  languages.ruby.enable = true;
  languages.ruby.bundler.enable = true;

#  scripts.jekyll-serve.exec = ''
#    bundle exec jekyll serve --force_polling
#  '';

#  scripts.jekyll-build.exec = ''
#    bundle exec jekyll build --future
#  '';

   tasks = {
      "jekyll:setup".exec = "bundle install";
      "devenv:enterShell".after = [ "jekyll:setup" ];
   };

  processes = {
    server = {
      exec = "bundle exec jekyll serve";
    };
  };

  # git-hooks.hooks.shellcheck.enable = true;
}
