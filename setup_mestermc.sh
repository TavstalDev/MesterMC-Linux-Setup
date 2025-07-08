#!/bin/bash
set -e # Azonnali leállás, ha bármely parancs hibával tér vissza

# Függvény parancs létezésének ellenőrzésére
command_exists () {
    type "$1" &> /dev/null ;
}

# Az aktuális Linux felhasználónév lekérése
LINUX_USERNAME="$USER"
if [ -z "$LINUX_USERNAME" ]; then
    LINUX_USERNAME=$(whoami) # Tartalék, ha a $USER nincs beállítva valamilyen okból
fi

echo "Észlelt Linux felhasználónév: $LINUX_USERNAME"

# Változók inicializálása a generált indító fájl nyomon követéséhez
GENERATED_LAUNCHER_FILE=""
LAUNCHER_TYPE_CHOSEN=""

## 1. Wine ellenőrzése és telepítése
echo "--- Wine telepítés ellenőrzése ---"

if command_exists wine; then
    echo "A Wine már telepítve van."
else
    echo "Wine nem található. Disztribúció észlelése a Wine telepítéséhez..."
    if command_exists apt-get; then
        # Debian/Ubuntu
        echo "Észlelt disztribúció: Debian/Ubuntu. Wine telepítése..."
        sudo dpkg --add-architecture i386
        sudo mkdir -pm755 /etc/apt/keyrings
        sudo apt update
        sudo apt install wine wine32 wine64 -y
        sudo apt install winetricks -y
        sudo apt install winbind -y
        #winecfg
    elif command_exists dnf; then
        # Fedora
        echo "Észlelt disztribúció: Fedora. Wine telepítése..."
        FEDORA_VERSION=$(grep -oP '(?<=release )[0-9]+' /etc/redhat-release)
        if [ -z "$FEDORA_VERSION" ]; then
            echo "Nem sikerült észlelni a Fedora verzióját. Kérjük, szükség esetén frissítse a '39' értéket a szkriptben."
            FEDORA_VERSION="39" # Alapértelmezett: 39, ha az észlelés sikertelen
        fi
        sudo dnf check-update
        sudo dnf install wine winetricks wine-mono -y
    elif command_exists pacman; then
        # Arch Linux
        echo "Észlelt disztribúció: Arch Linux. Wine telepítése..."
        echo "# Ha a telepítés sikertelen, az utalhat a multilib repo hiányára. Kérjük, győződjön meg róla, hogy engedélyezte a multilibet a /etc/pacman.conf fájlban."
        sudo pacman -Sy
        sudo pacman -S wine wine-mono wine_gecko -y
    else
        echo "Nem sikerült meghatározni a disztribúciót, vagy nem támogatott. Kérjük, telepítse a Wine-t manuálisan."
        exit 1
    fi
    echo "Wine telepítés befejeződött."
fi

## 2. OpenJDK 21 ellenőrzése és telepítése
echo ""
echo "--- OpenJDK 21 telepítés ellenőrzése ---"

if command_exists java; then
    JAVA_VERSION_OUTPUT=$(java -version 2>&1)
    if echo "$JAVA_VERSION_OUTPUT" | grep -qE "openjdk version \"21\.|java version \"21\."; then
        echo "OpenJDK 21 már telepítve van."
    else
        echo "A telepített Java verzió nem OpenJDK 21. Kísérlet a telepítésre..."
        if command_exists apt-get; then
            # Debian/Ubuntu
            echo "Észlelt disztribúció: Debian/Ubuntu. OpenJDK 21 telepítése..."
            sudo apt update
            wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
            sudo dpkg -i jdk-21_linux-x64_bin.deb
            sudo rm -rf jdk-21_linux-x64_bin.deb
        elif command_exists dnf; then
            # Fedora
            echo "Észlelt disztribúció: Fedora. OpenJDK 21 telepítése..."
            sudo dnf install java-21-openjdk -y
        elif command_exists pacman; then
            # Arch Linux
            echo "Észlelt disztribúció: Arch Linux. OpenJDK 21 telepítése..."
            sudo pacman -S jdk21-openjdk -y
        else
            echo "Nem sikerült meghatározni a disztribúciót, vagy nem támogatott. Kérjük, telepítse az OpenJDK 21-et manuálisan."
            exit 1
        fi
        echo "OpenJDK 21 telepítés befejeződött."
    fi
else
    echo "Java nem található. Kísérlet az OpenJDK 21 telepítésére..."
    if command_exists apt-get; then
        # Debian/Ubuntu
        echo "Észlelt disztribúció: Debian/Ubuntu. OpenJDK 21 telepítése..."
        sudo apt update
        wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb
        sudo dpkg -i jdk-21_linux-x64_bin.deb
        sudo rm -rf jdk-21_linux-x64_bin.deb
    elif command_exists dnf; then
        # Fedora
        echo "Észlelt disztribúció: Fedora. OpenJDK 21 telepítése..."
        sudo dnf install java-21-openjdk -y
    elif command_exists pacman; then
        # Arch Linux
        echo "Észlelt disztribúció: Arch Linux. OpenJDK 21 telepítése..."
        sudo pacman -S jdk21-openjdk -y
    else
        echo "Nem sikerült meghatározni a disztribúciót, vagy nem támogatott. Kérjük, telepítse az OpenJDK 21-et manuálisan."
        exit 1
    fi
    echo "OpenJDK 21 telepítés befejeződött."
fi

## 3. Opcionális Wine előtag (prefix) helyének kérése
echo ""
read -p "Adja meg az opcionális Wine előtag helyét (pl. ~/.wine_mestermc), vagy nyomja meg az Entert az alapértelmezett használatához: " WINE_PREFIX_LOCATION_INPUT

if [ -z "$WINE_PREFIX_LOCATION_INPUT" ]; then
    export SELECTED_WINE_PREFIX="$HOME/.wine"
    echo "Alapértelmezett Wine előtag használata (~/.wine)."
else
    export SELECTED_WINE_PREFIX="$WINE_PREFIX_LOCATION_INPUT"
    echo "Wine előtag használata: $SELECTED_WINE_PREFIX"
fi

mkdir -p "$SELECTED_WINE_PREFIX" # Győződjön meg róla, hogy az előtag könyvtár létezik
export WINEPREFIX="$SELECTED_WINE_PREFIX" # Exportálás az aktuális szkript futtatásához

## 4. PowerShell Wrapper telepítése
echo ""
echo "--- PowerShell Wrapper telepítése ---"
if [ ! -f install_pwshwrapper.exe ]; then
    echo "PowerShell Wrapper telepítő letöltése..."
    wget https://github.com/PietJankbal/powershell-wrapper-for-wine/raw/master/install_pwshwrapper.exe
else
    echo "PowerShell Wrapper telepítő már létezik."
fi

echo "PowerShell Wrapper telepítő futtatása..."
wine install_pwshwrapper.exe

echo "PowerShell Wrapper telepítés ellenőrzése..."
wine powershell -noni -c 'echo "PowerShell Wrapper sikeresen telepítve!"'

## 5. MesterMC telepítő letöltése és futtatása
echo ""
echo "--- MesterMC telepítő letöltése és indítása ---"
MESTERMC_INSTALLER_URL="https://mestermc.eu/mestermc.exe"
MESTERMC_INSTALLER_FILENAME="MesterMC.exe"

if [ ! -f "$MESTERMC_INSTALLER_FILENAME" ]; then
    echo "MesterMC telepítő letöltése a(z) $MESTERMC_INSTALLER_URL címről..."
    wget -O "$MESTERMC_INSTALLER_FILENAME" "$MESTERMC_INSTALLER_URL"
    if [ $? -ne 0 ]; then
        echo "Hiba: Nem sikerült letölteni a MesterMC.exe telepítőt. Kérjük, ellenőrizze az URL-t vagy az internetkapcsolatot."
        exit 1
    fi
else
    echo "A MesterMC.exe telepítő már létezik."
fi

echo "MesterMC.exe telepítő futtatása. Kérjük, kövesse az utasításokat."
wine "$MESTERMC_INSTALLER_FILENAME"

if [ -f "MesterMC.desktop" ]; then
    rm -f "MesterMC.desktop"
    echo "MesterMC.desktop eltávolítva."
fi
echo "MesterMC telepítő befejeződött. Indító fájl létrehozása következik."

## 6. MesterMC indító fájl generálása
is_kde=false

if [[ "$XDG_CURRENT_DESKTOP" == *KDE* ]] || [[ "$DESKTOP_SESSION" == *plasma* ]]; then
    is_kde=true
elif pgrep -x plasmashell >/dev/null || pgrep -x kded5 >/dev/null; then
    is_kde=true
fi

echo ""
if $is_kde; then
    while true; do
        read -p "Milyen indító fájlt szeretne létrehozni? (sh - shell szkript, desktop - asztali indító): " LAUNCHER_CHOICE
        case "$LAUNCHER_CHOICE" in
            sh|SH)
                LAUNCHER_TYPE_CHOSEN="sh"
                break
                ;;
            desktop|DESKTOP)
                LAUNCHER_TYPE_CHOSEN="desktop"
                break
                ;;
            *)
                echo "Érvénytelen választás. Kérjük, írjon 'sh' vagy 'desktop'."
                ;;
        esac
    done
else
    echo "Nem KDE környezet észlelve. Automatikusan sh indító fájl lesz létrehozva."
    LAUNCHER_TYPE_CHOSEN="sh"
fi

# A MesterMC.jar telepítési útvonalának meghatározása a Wine előtagon belül
MESTERMC_DIR_LOCATION_IN_WINE="drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC"
MESTERMC_DIR_FULL_PATH="$SELECTED_WINE_PREFIX/$MESTERMC_DIR_LOCATION_IN_WINE"
MESTERMC_JAR_FULL_PATH="$MESTERMC_DIR_FULL_PATH/MesterMC.jar"

# Az ikon útvonala a Wine előtagon belül
ICON_LOCATION_IN_WINE="drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC/icon.ico"
ICON_FULL_PATH="$SELECTED_WINE_PREFIX/$ICON_LOCATION_IN_WINE"

if [ "$LAUNCHER_TYPE_CHOSEN" == "sh" ]; then
    LAUNCHER_SCRIPT_NAME="launch_mestermc.sh"
    GENERATED_LAUNCHER_FILE="$LAUNCHER_SCRIPT_NAME"
    echo "MesterMC indító szkript generálása: $LAUNCHER_SCRIPT_NAME"

cat <<EOF > "$LAUNCHER_SCRIPT_NAME"
#!/bin/bash
set -e # Azonnali leállás, ha bármely parancs hibával tér vissza
# MesterMC Indító Szkript

# Állítsa be a telepítés során használt Wine előtagot
export WINEPREFIX="$SELECTED_WINE_PREFIX"

# A MesterMC.jar teljes útvonalának meghatározása a Wine előtagon belül
# Ez az útvonal a MesterMC általános telepítési viselkedésén alapul.
# A Linux felhasználónevet használja Windows felhasználói profilnévként.
MESTERMC_JAR_FULL_PATH_IN_LAUNCHER="\$WINEPREFIX/drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC/MesterMC.jar"
JAR_DIR_IN_LAUNCHER="\$(dirname "\$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER")"

echo "MesterMC indítása a következő Wine előtaggal: \$WINEPREFIX"

# Győződjön meg róla, hogy a .jar fájl létezik, mielőtt megpróbálná futtatni
if [ ! -f "\$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER" ]; then
    echo "Hiba: A MesterMC.jar nem található a következő helyen: \$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER."
    echo "Kérjük, győződjön meg róla, hogy a MesterMC helyesen lett telepítve az AppData/Roaming/MesterMC könyvtárba a Wine előtagon belül."
    exit 1
fi

# Váltson arra a könyvtárra, ahol a .jar található, mielőtt végrehajtaná
# Ez néha megakadályozhatja a Java alkalmazáson belüli relatív útvonalakkal kapcsolatos problémákat.
cd "\$JAR_DIR_IN_LAUNCHER" || { echo "Hiba: Nem sikerült a könyvtárra váltani: \$JAR_DIR_IN_LAUNCHER"; exit 1; }

# MesterMC.jar futtatása Java segítségével
cd $MESTERMC_DIR_FULL_PATH && java -jar $MESTERMC_JAR_FULL_PATH
EOF

    chmod +x "$LAUNCHER_SCRIPT_NAME"
    echo "A **MesterMC** indító szkript '**$LAUNCHER_SCRIPT_NAME**' sikeresen létrejött!"
    echo "Most már futtathatja a **MesterMC**-t a következő paranccsal: **./$LAUNCHER_SCRIPT_NAME**"

elif [ "$LAUNCHER_TYPE_CHOSEN" == "desktop" ]; then
    LAUNCHER_DESKTOP_NAME="MesterMC.desktop"
    GENERATED_LAUNCHER_FILE="$LAUNCHER_DESKTOP_NAME"
    echo "MesterMC asztali indító fájl generálása: $LAUNCHER_DESKTOP_NAME"

cat <<EOF > "$LAUNCHER_DESKTOP_NAME"
[Desktop Entry]
Name=MesterMC
Comment=Play MesterMC through Wine
Exec=cd $MESTERMC_DIR_FULL_PATH && nohup java -jar $MESTERMC_JAR_FULL_PATH > /dev/null 2>&1 &
Icon=$ICON_FULL_PATH
Terminal=false
Type=Application
Categories=Game;Minecraft;
StartupNotify=true
EOF

    chmod +x "$LAUNCHER_DESKTOP_NAME"
    echo "A **MesterMC** asztali indító fájl '**$LAUNCHER_DESKTOP_NAME**' sikeresen létrejött!"
    read -p "Áthelyezi a '$LAUNCHER_DESKTOP_NAME' fájlt az alkalmazásmenübe való megjelenítéshez? (i/n): " MOVE_DESKTOP_CHOICE
    if [[ "$MOVE_DESKTOP_CHOICE" =~ ^[iI]$ ]]; then
        mkdir -p "$HOME/.local/share/applications"
        mv "$LAUNCHER_DESKTOP_NAME" "$HOME/.local/share/applications/"
        GENERATED_LAUNCHER_FILE="$HOME/.local/share/applications/$LAUNCHER_DESKTOP_NAME" # Frissítjük az útvonalat a takarításhoz
        echo "Az indító fájl áthelyezve ide: **$HOME/.local/share/applications/**"
    fi
    echo "Most már elindíthatja a **MesterMC**-t az alkalmazásmenüből vagy duplán kattintva a '$LAUNCHER_DESKTOP_NAME' fájlra (ha az aktuális könyvtárban maradt)."
fi

echo ""
echo "A szkript befejeződött."


## 7. Takarítás
echo ""
echo "Takarítás..."

if [ -f "install_pwshwrapper.exe" ]; then
    rm -f "install_pwshwrapper.exe"
    echo "install_pwshwrapper.exe eltávolítva."
fi

if [ -f "$MESTERMC_INSTALLER_FILENAME" ]; then
    rm -f "$MESTERMC_INSTALLER_FILENAME"
    echo "$MESTERMC_INSTALLER_FILENAME eltávolítva."
fi

if [ -f "MesterMC.ink" ]; then
    rm -f "MesterMC.ink"
    echo "MesterMC.ink eltávolítva."
fi

if [ -f "MesterMC.lnk" ]; then
    rm -f "MesterMC.lnk"
    echo "MesterMC.lnk eltávolítva."
fi

echo "A takarítás befejeződött."
