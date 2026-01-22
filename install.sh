#!/bin/bash
#
# install.sh
#
# Este script configura un entorno de terminal completo, inspirado en
# la automatización de scripts como el de Chris Titus, pero usando tus
# configuraciones personales.
#
# Pasos que realiza:
# 1. Instala dependencias (git, tmux, herramientas de compilación).
# 2. Instala herramientas modernas de CLI (Starship, eza, bat, fzf).
# 3. Descarga e instala una Nerd Font (FiraCode).
# 4. Instala la última versión de Neovim (AppImage).
# 5. Clona/actualiza este repositorio de dotfiles.
# 6. Crea enlaces simbólicos para las configuraciones.
# 7. Instala el gestor de plugins de Tmux (tpm).
# 8. Sincroniza los plugins de Neovim (LazyVim).
#

set -e

# --- Helper Functions ---
print_info() { echo -e "\e[34mINFO: $1\e[0m"; }
print_success() { echo -e "\e[32mSUCCESS: $1\e[0m"; }
print_error() { echo -e "\e[31mERROR: $1\e[0m"; }

# --- Variables ---
REPO_URL="https://github.com/gzlo/gzl-terminal.git"
DOTFILES_DIR="$HOME/dotfiles" # Se clona aquí, no en .dotfiles, para evitar conflictos con el script
FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip"
NVIM_URL="https://github.com/neovim/neovim/releases/latest/download/nvim.appimage"

# --- Installation Functions ---

install_dependencies() {
    print_info "Instalando dependencias del sistema..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update
        sudo apt-get install -y git tmux curl unzip build-essential fzf ripgrep
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y git tmux curl unzip fzf ripgrep 'dnf-command(builddep)'
        sudo dnf builddep -y neovim
    elif command -v pacman &>/dev/null; then
        sudo pacman -Syu --noconfirm git tmux curl unzip fzf ripgrep base-devel
    else
        print_error "Gestor de paquetes no soportado. Por favor, instala manualmente: git, tmux, curl, unzip, fzf, ripgrep."
        exit 1
    fi
}

install_modern_cli() {
    print_info "Instalando herramientas modernas de CLI..."
    # Starship
    print_info "Instalando Starship prompt..."
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    
    # Eza (reemplazo de ls)
    if ! command -v eza &>/dev/null; then
        print_info "Instalando eza..."
        cargo install eza
    fi

    # Bat (reemplazo de cat)
    if ! command -v batcat &>/dev/null && ! command -v bat &>/dev/null; then
        print_info "Instalando bat..."
        cargo install bat
    fi
}


install_nerd_font() {
    print_info "Instalando FiraCode Nerd Font..."
    FONT_DIR="$HOME/.local/share/fonts"
    mkdir -p "$FONT_DIR"
    cd "$FONT_DIR"
    curl -fLo "FiraCode.zip" "$FONT_URL"
    unzip -o FiraCode.zip
    rm FiraCode.zip
    fc-cache -f -v
    cd -
}

install_neovim() {
    print_info "Instalando la última versión de Neovim..."
    if [ ! -f /usr/local/bin/nvim ]; then
        curl -fLo "$HOME/nvim.appimage" "$NVIM_URL"
        chmod u+x "$HOME/nvim.appimage"
        # Mover a una ubicación del PATH. Requiere sudo.
        sudo mv "$HOME/nvim.appimage" /usr/local/bin/nvim
    else
        print_info "Neovim ya parece estar instalado en /usr/local/bin/nvim."
    fi
}

# --- Main Execution ---

main() {
    install_dependencies
    # install_modern_cli # Comentado por ahora para evitar dependencias de RUST/Cargo
    install_nerd_font
    install_neovim

    print_info "Clonando/actualizando repositorio de dotfiles..."
    if [ -d "$DOTFILES_DIR" ]; then
        print_info "Directorio de dotfiles encontrado. Actualizando..."
        git -C "$DOTFILES_DIR" pull
    else
        git clone "$REPO_URL" "$DOTFILES_DIR"
    fi
    
    cd "$DOTFILES_DIR"

    print_info "Creando enlaces simbólicos..."
    mkdir -p "$HOME/.config"
    
    # Bash
    ln -sf "$DOTFILES_DIR/bashrc" "$HOME/.bashrc"
    
    # Neovim
    ln -sf "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
    
    # Tmux (solo si existe el archivo)
    if [ -f "$DOTFILES_DIR/tmux.conf" ]; then
        ln -sf "$DOTFILES_DIR/tmux.conf" "$HOME/.tmux.conf"
    fi
    
    print_info "Configurando Starship en .bashrc..."
    # Asegurarse de que no se duplique
    if ! grep -q 'starship init bash' "$HOME/.bashrc"; then
        echo 'eval "$(starship init bash)"' >> "$HOME/.bashrc"
    fi
    
    print_info "Instalando Tmux Plugin Manager (tpm)..."
    TPM_DIR="$HOME/.tmux/plugins/tpm"
    if [ ! -d "$TPM_DIR" ]; then
        git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    fi
    
    print_info "Sincronizando plugins de Neovim (LazyVim)..."
    nvim --headless "+Lazy! sync" +qa
    
    print_success "¡Entorno configurado!"
    print_info "Por favor, reinicia tu terminal o ejecuta 'source ~/.bashrc'."
    print_info "En Tmux, recuerda presionar 'prefix + I' para instalar los plugins."
}

main "$@"
