set shell := ["zsh", "-uc"]
set positional-arguments

# List all available recipes
@help:
  just --list

# Install dependencies
@install: (needs "bun")
  bun install

  print "\n⚠️ A manual step is required to deploy the slideshow to GitHub Pages:"
  print "Go to the repository Settings -> Pages -> Source and select GitHub Actions."

# Update dependencies
@update:
  bun update

# Create a git and GitHub repo, install dependencies
init: ensure-git ensure-github install

# Format the slides
@fmt *args="slides.md":
  bun slidev format -- "$@"

# Display a live-preview of the slideshow
@preview slides="slides.md":
  bun slidev --open -- "$1"

# Build the slides to HTML
@build:
  bun slidev build --base=/llm-inference-arithmetics

# Clean build dir
@clean:
  rm -rf dist

# Test whether slides can be built to HTML
@test-build: build clean

# Test the release bump
@test-bump: (needs "cz")
  cz bump --check-consistency --dry-run

# Test the release workflow
@test-release: fmt test-build test-bump

# Bump the slideshow version
@release: test-release
  cz bump
  git push
  git push --tag

# Assert a command is available
[private]
needs *commands:
  #!/usr/bin/env zsh
  set -euo pipefail
  for cmd in "$@"; do
    if ! command -v $cmd &> /dev/null; then
      print "$cmd binary not found. Did you forget to install it?"
      exit 1
    fi
  done

# Create a local git repo if not in one
[private]
ensure-git: (needs "git")
  #! /usr/bin/env zsh
  if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    git init
  fi

# Ask to create a remote repo if not exists
[private]
ensure-github:
  #! /usr/bin/env zsh
  if ! gh repo list baggiponte | grep --quiet "/\bllm-inference-arithmetics\b"; then
    while true; do
      print -n "No remote repository found. Do you want to create a new repository? (y/n): "
      read -r REPLY

      case $REPLY in
        [Yy])
          print -n "Do you want to create a private repository? (y/n): "
          read -r PRIVATE
          case $PRIVATE in
            [Yy])
              gh repo create baggiponte/llm-inference-arithmetics --private --source=.
              ;;
            [Nn])
              gh repo create baggiponte/llm-inference-arithmetics --public --source=.
              ;;
            *)
              print "Invalid input. Please enter 'y' or 'n'."
              ;;
          esac
          break
          ;;
        [Nn])
          break
          ;;
        *)
          print "Invalid input. Please enter 'y' or 'n'."
          ;;
      esac
    done
  else
    while true; do
      print -n "A repo with this name already exists. Do you want to add it as a remote? (y/n): "
      read -r REPLY

      case $REPLY in
        [Yy])
          git remote add origin git@github.com:baggiponte/llm-inference-arithmetics
          break
          ;;
        [Nn])
          break
          ;;
        *)
          print "Invalid input. Please enter 'y' or 'n'."
          ;;
      esac
    done
  fi

