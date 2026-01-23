# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# --- PATH configuration (Inyectado por Gemini CLI para robustez) ---
# Asegura que los directorios esenciales del sistema estén presentes al inicio del PATH.
# Esto es crucial para que comandos básicos como 'ls', 'cat', 'mv', etc., funcionen siempre.
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

# Añadir directorios binarios específicos del usuario si existen y no están ya en el PATH
if [ -d "$HOME/.local/bin" ]; then
    case ":$PATH:" in
        *":$HOME/.local/bin:"*) ;;
        *) export PATH="$HOME/.local/bin:$PATH" ;;
    esac
fi
if [ -d "$HOME/.console-ninja/.bin" ]; then
    case ":$PATH:" in
        *":$HOME/.console-ninja/.bin:"*) ;;
        *) export PATH="$HOME/.console-ninja/.bin:$PATH" ;;
        esac
fi
# --- Fin de la configuración de PATH ---


# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# Starship prompt configuration (Inyectado por Gemini CLI)
eval "$(starship init bash)"
