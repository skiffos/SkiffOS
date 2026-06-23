# If not running interactively, don't do anything.
case $- in
    *i*) ;;
    *) return;;
esac

skiff_wsl_windows_path_file=/mnt/persist/skiff-overlays/skiff-init/wsl-windows-path
if [ -r "${skiff_wsl_windows_path_file}" ]; then
    while IFS= read -r skiff_wsl_path_dir; do
        case "${skiff_wsl_path_dir}" in
            /mnt/[A-Za-z]/*)
                case ":${PATH}:" in
                    *:"${skiff_wsl_path_dir}":*) ;;
                    *) PATH="${PATH:+${PATH}:}${skiff_wsl_path_dir}" ;;
                esac
                ;;
        esac
    done < "${skiff_wsl_windows_path_file}"
    export PATH
fi
unset skiff_wsl_windows_path_file skiff_wsl_path_dir
