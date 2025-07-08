#!/bin/bash
set -e # Azonnali leállás, ha bármely parancs hibával tér vissza

# --- Szkript Metaadatok ---
# Fájlnév: mestermc_telepito.sh
# Leírás: Ez a szkript automatizálja a MesterMC telepítését és beállítását Linux rendszeren Wine segítségével.
#          Ellenőrzi és telepíti a szükséges függőségeket (Wine, OpenJDK 21), letölti és futtatja a MesterMC telepítőt,
#          valamint létrehoz egy indító fájlt (shell szkript vagy asztali indító) a MesterMC könnyű eléréséhez.
# Szerző: [Solymosi 'Tavstal' Zoltán]
# Dátum: 2025. július 8.
# Verzió: 1.0
# 

# --- Fontos Megjegyzés ---
# Ez a szkript egy független projekt, és nem áll semmilyen hivatalos kapcsolatban a MesterMC fejlesztőivel vagy üzemeltetőivel.
# A szkriptet saját felelősségére használja.
# ---


# --- Függvények ---

# command_exists: Ellenőrzi, hogy egy adott parancs létezik-e a rendszer PATH-jában.
# Használat: if command_exists <parancs_neve>; then ... fi
command_exists () {
    type "$1" &> /dev/null
}

# print_header: Egy formázott fejlécet nyomtat a konzolra.
# Használat: print_header "Fejléc szövege"
print_header() {
    echo ""
    echo "--- $1 ---"
}

# --- Változók Inicializálása ---

# Az aktuális Linux felhasználónév lekérése. Fontos a Wine felhasználói profil útvonalainak meghatározásához.
LINUX_USERNAME="$USER"
if [ -z "$LINUX_USERNAME" ]; then
    LINUX_USERNAME=$(whoami) # Tartalék, ha a $USER változó nincs beállítva.
fi
echo "Észlelt Linux felhasználónév: $LINUX_USERNAME"

# Változók a generált indító fájl nyomon követéséhez.
GENERATED_LAUNCHER_FILE=""
LAUNCHER_TYPE_CHOSEN=""
SELECTED_WINE_PREFIX="" # Globálissá téve a későbbi használathoz.

# --- Fő Szkript Logika ---

print_header "Wine Telepítés Ellenőrzése és Beállítása"

# 1. Wine ellenőrzése és telepítése
if command_exists wine; then
    echo "A Wine már telepítve van. Folytatás a következő lépéssel."
else
    echo "Wine nem található. Megpróbáljuk észlelni a disztribúciót a Wine telepítéséhez..."
    if command_exists apt-get; then
        # Debian/Ubuntu alapú rendszerek (pl. Ubuntu, Mint)
        echo "Észlelt disztribúció: Debian/Ubuntu."
        echo "Wine telepítése. Ez eltarthat egy ideig..."
        sudo dpkg --add-architecture i386 # 32 bites architektúra engedélyezése
        sudo mkdir -pm755 /etc/apt/keyrings # Kulcsok könyvtárának biztosítása
        sudo apt update # Csomaglisták frissítése
        sudo apt install wine wine32 wine64 -y # Wine fő csomagok
        sudo apt install winetricks -y # Winetricks telepítése (segédprogram a Wine-hoz)
        sudo apt install winbind -y # Winbind a jobb Windows hálózati integrációhoz
        # Tipp: A 'winecfg' parancs futtatásával beállíthatja a Wine-t az első indítás után.
    elif command_exists dnf; then
        # Fedora alapú rendszerek
        echo "Észlelt disztribúció: Fedora."
        echo "Wine telepítése..."
        # Megpróbálja észlelni a Fedora verzióját, hogy specifikus tárolókat használjon.
        FEDORA_VERSION=$(grep -oP '(?<=release )[0-9]+' /etc/redhat-release)
        if [ -z "$FEDORA_VERSION" ]; then
            echo "Nem sikerült észlelni a Fedora verzióját. Alapértelmezett '39' használata. Kérjük, ellenőrizze, ha ez hibát okoz."
            FEDORA_VERSION="39" # Alapértelmezett: 39, ha az észlelés sikertelen.
        fi
        sudo dnf check-update # Csomagok frissítése
        sudo dnf install wine winetricks wine-mono -y # Wine, Winetricks és Wine-Mono (Microsoft .NET alternatíva)
    elif command_exists pacman; then
        # Arch Linux alapú rendszerek
        echo "Észlelt disztribúció: Arch Linux."
        echo "Wine telepítése..."
        echo "# Fontos: Ha a telepítés sikertelen, ellenőrizze, hogy a 'multilib' tároló engedélyezve van-e a /etc/pacman.conf fájlban."
        sudo pacman -Sy # Csomaglisták szinkronizálása
        sudo pacman -S wine wine-mono wine_gecko -y # Wine, Wine-Mono és Wine-Gecko (Internet Explorer alternatíva)
    else
        echo "Hiba: Nem sikerült meghatározni a Linux disztribúciót, vagy az nem támogatott."
        echo "Kérjük, telepítse a Wine-t manuálisan a disztribúciójának megfelelő módon, majd futtassa újra ezt a szkriptet."
        exit 1
    fi
    echo "Wine telepítés befejeződött."
fi

print_header "OpenJDK 21 Telepítés Ellenőrzése és Beállítása"

# 2. OpenJDK 21 ellenőrzése és telepítése
if command_exists java; then
    JAVA_VERSION_OUTPUT=$(java -version 2>&1)
    if echo "$JAVA_VERSION_OUTPUT" | grep -qE "openjdk version \"21\.|java version \"21\."; then
        echo "OpenJDK 21 már telepítve van. Folytatás a következő lépéssel."
    else
        echo "A telepített Java verzió nem OpenJDK 21. Megpróbáljuk telepíteni az OpenJDK 21-et..."
        if command_exists apt-get; then
            echo "Észlelt disztribúció: Debian/Ubuntu. OpenJDK 21 telepítése..."
            sudo apt update
            # Az Oracle JDK közvetlen letöltése és telepítése, mivel az OpenJDK 21 nem mindig érhető el azonnal a tárolókban.
            # Alternatívaként használhatja az 'apt install openjdk-21-jdk -y' parancsot, ha elérhető.
            wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb -O jdk-21_linux-x64_bin.deb
            sudo dpkg -i jdk-21_linux-x64_bin.deb
            rm -f jdk-21_linux-x64_bin.deb # A letöltött .deb fájl törlése
        elif command_exists dnf; then
            echo "Észlelt disztribúció: Fedora. OpenJDK 21 telepítése..."
            wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.rpm -O jdk-21_linux-x64_bin.rpm
            sudo dnf install jdk-21_linux-x64_bin.rpm -y
            rm -f jdk-21_linux-x64_bin.rpm # A letöltött .rpm fájl törlése
        elif command_exists pacman; then
            echo "Észlelt disztribúció: Arch Linux. OpenJDK 21 telepítése..."
            sudo pacman -S jdk21-openjdk -y
        else
            echo "Hiba: Nem sikerült meghatározni a disztribúciót, vagy nem támogatott."
            echo "Kérjük, telepítse az OpenJDK 21-et manuálisan, majd futtassa újra ezt a szkriptet."
            exit 1
        fi
        echo "OpenJDK 21 telepítés befejeződött."
    fi
else
    echo "Java nem található. Megpróbáljuk telepíteni az OpenJDK 21-et..."
    if command_exists apt-get; then
        echo "Észlelt disztribúció: Debian/Ubuntu. OpenJDK 21 telepítése..."
        sudo apt update
        wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.deb -O jdk-21_linux-x64_bin.deb
        sudo dpkg -i jdk-21_linux-x64_bin.deb
        rm -f jdk-21_linux-x64_bin.deb
    elif command_exists dnf; then
        echo "Észlelt disztribúció: Fedora. OpenJDK 21 telepítése..."
        wget https://download.oracle.com/java/21/latest/jdk-21_linux-x64_bin.rpm -O jdk-21_linux-x64_bin.rpm
        sudo dnf install jdk-21_linux-x64_bin.rpm -y
        rm -f jdk-21_linux-x64_bin.rpm # A letöltött .rpm fájl törlése
    elif command_exists pacman; then
        echo "Észlelt disztribúció: Arch Linux. OpenJDK 21 telepítése..."
        sudo pacman -S jdk21-openjdk -y
    else
        echo "Hiba: Nem sikerült meghatározni a disztribúciót, vagy nem támogatott."
        echo "Kérjük, telepítse az OpenJDK 21-et manuálisan, majd futtassa újra ezt a szkriptet."
        exit 1
    fi
    echo "OpenJDK 21 telepítés befejeződött."
fi

print_header "Wine Előtag (Prefix) Beállítása"

# 3. Opcionális Wine előtag (prefix) helyének kérése
# A Wine előtag egy önálló Wine környezet, amely segít elszigetelni a Windows programokat.
read -p "Adja meg az opcionális Wine előtag helyét (pl. ~/.wine_mestermc), vagy nyomja meg az Entert az alapértelmezett (~/.wine) használatához: " WINE_PREFIX_LOCATION_INPUT

if [ -z "$WINE_PREFIX_LOCATION_INPUT" ]; then
    export SELECTED_WINE_PREFIX="$HOME/.wine" # Alapértelmezett Wine előtag
    echo "Az alapértelmezett Wine előtagot fogjuk használni: ~/.wine"
else
    export SELECTED_WINE_PREFIX="$WINE_PREFIX_LOCATION_INPUT" # Felhasználó által megadott Wine előtag
    echo "A megadott Wine előtagot fogjuk használni: $SELECTED_WINE_PREFIX"
fi

mkdir -p "$SELECTED_WINE_PREFIX" # Győződjön meg róla, hogy az előtag könyvtár létezik.
export WINEPREFIX="$SELECTED_WINE_PREFIX" # Exportálja a WINEPREFIX változót, hogy a Wine a szkript hátralévő részében ezt az előtagot használja.

print_header "PowerShell Wrapper Telepítése"

# 4. PowerShell Wrapper telepítése
# A PowerShell Wrapper segít abban, hogy a PowerShell szkriptek is megfelelően fussanak Wine alatt.
# A MesterMC telepítője (és esetleg maga a játék) is használhat PowerShellt.
WRAPPER_INSTALLER="install_pwshwrapper.exe"
if [ ! -f "$WRAPPER_INSTALLER" ]; then
    echo "PowerShell Wrapper telepítő letöltése a GitHub-ról..."
    wget https://github.com/PietJankbal/powershell-wrapper-for-wine/raw/master/install_pwshwrapper.exe -O "$WRAPPER_INSTALLER"
    if [ $? -ne 0 ]; then
        echo "Hiba: Nem sikerült letölteni a PowerShell Wrapper telepítőt. Kérjük, ellenőrizze az internetkapcsolatot."
        exit 1
    fi
else
    echo "PowerShell Wrapper telepítő már létezik. Kihagyjuk a letöltést."
fi

echo "PowerShell Wrapper telepítő futtatása Wine segítségével. Kérjük, kövesse az esetleges utasításokat..."
WINEDEBUG=+err wine "$WRAPPER_INSTALLER"

echo "Ellenőrizzük, hogy a PowerShell Wrapper sikeresen települt-e..."
if WINEDEBUG=+err wine powershell -noni -c 'echo "PowerShell Wrapper sikeresen telepítve!"'; then
    echo "PowerShell Wrapper sikeresen telepítve és működik."
else
    echo "Figyelem: A PowerShell Wrapper telepítése vagy működése problémákba ütközött. Ez hatással lehet a MesterMC bizonyos funkcióira."
fi

print_header "MesterMC Telepítő Letöltése és Indítása"

# 5. MesterMC telepítő letöltése és futtatása
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
    echo "A MesterMC.exe telepítő már létezik. Kihagyjuk a letöltést."
fi

echo "MesterMC.exe telepítő futtatása Wine segítségével."
echo "Kérjük, kövesse a telepítő ablakában megjelenő utasításokat."
echo "Fontos: A telepítés során válassza ki a 'Minden felhasználó' telepítési lehetőséget, ha van ilyen, vagy hagyja az alapértelmezett telepítési útvonalat."
WINEDEBUG=+err wine "$MESTERMC_INSTALLER_FILENAME"

# Eltávolítjuk az esetlegesen generált MesterMC.desktop fájlt a jelenlegi könyvtárból, ha a telepítő létrehozta.
if [ -f "MesterMC.desktop" ]; then
    rm -f "MesterMC.desktop"
    echo "A MesterMC.desktop ideiglenes fájl eltávolítva."
fi
echo "MesterMC telepítő befejeződött. Most jön az indító fájl generálása."

print_header "MesterMC Indító Fájl Generálása"

# 6. MesterMC indító fájl generálása
# A szkript lehetőséget biztosít egy shell szkript (.sh) vagy egy asztali indító (.desktop) létrehozására.
# KDE környezetben kérdezi a felhasználót, egyébként alapértelmezetten shell szkriptet hoz létre.

is_kde=false
# Különböző módszerek a KDE környezet észlelésére.
if [[ "$XDG_CURRENT_DESKTOP" == *KDE* ]] || [[ "$DESKTOP_SESSION" == *plasma* ]]; then
    is_kde=true
elif pgrep -x plasmashell >/dev/null || pgrep -x kded5 >/dev/null; then
    is_kde=true
fi

if $is_kde; then
    echo "KDE környezet észlelve."
    while true; do
        read -p "Milyen típusú indító fájlt szeretne létrehozni? (sh - shell szkript, desktop - asztali indító): " LAUNCHER_CHOICE
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
    echo "Nem KDE környezet észlelve. Automatikusan 'sh' indító fájl lesz létrehozva."
    LAUNCHER_TYPE_CHOSEN="sh"
fi

# A MesterMC.jar és az ikon várható telepítési útvonalának meghatározása a Wine előtagon belül.
# Ez feltételezi a MesterMC alapértelmezett telepítési helyét a Wine környezetben.
MESTERMC_DIR_LOCATION_IN_WINE="drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC"
MESTERMC_DIR_FULL_PATH="$SELECTED_WINE_PREFIX/$MESTERMC_DIR_LOCATION_IN_WINE"
MESTERMC_JAR_FULL_PATH="$MESTERMC_DIR_FULL_PATH/MesterMC.jar"

# Az ikon útvonala a Wine előtagon belül.
ICON_LOCATION_IN_WINE="drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC/icon.ico"
ICON_FULL_PATH="$SELECTED_WINE_PREFIX/$ICON_LOCATION_IN_WINE"

# Ellenőrizzük, hogy a MesterMC.jar fájl létezik-e a várt helyen.
if [ ! -f "$MESTERMC_JAR_FULL_PATH" ]; then
    echo "Hiba: A MesterMC.jar fájl nem található a várt helyen: $MESTERMC_JAR_FULL_PATH"
    echo "Kérjük, ellenőrizze, hogy a MesterMC telepítője sikeresen lefutott, és a játék a szokásos AppData/Roaming mappába települt."
    echo "Lehetséges, hogy manuálisan kell elindítania a MesterMC-t a Wine fájlböngészőjéből (wine explorer) a telepítés ellenőrzéséhez."
    exit 1
fi

if [ "$LAUNCHER_TYPE_CHOSEN" == "sh" ]; then
    # Shell szkript generálása (.sh fájl)
    LAUNCHER_SCRIPT_NAME="launch_mestermc.sh"
    GENERATED_LAUNCHER_FILE="$LAUNCHER_SCRIPT_NAME"
    echo "MesterMC indító szkript generálása: $LAUNCHER_SCRIPT_NAME"

    cat <<EOF > "$LAUNCHER_SCRIPT_NAME"
#!/bin/bash
set -e # Azonnali leállás, ha bármely parancs hibával tér vissza
#
# MesterMC Indító Szkript
# Leírás: Ez a szkript elindítja a MesterMC-t a Wine környezetben.
#
# Használat: Futtassa a terminálból a következő paranccsal: ./launch_mestermc.sh
#

# Állítsa be a telepítés során használt Wine előtagot. Ez elengedhetetlen!
export WINEPREFIX="$SELECTED_WINE_PREFIX"

# A MesterMC.jar teljes útvonalának meghatározása a Wine előtagon belül.
# Ez az útvonal a MesterMC általános telepítési viselkedésén alapul.
MESTERMC_JAR_FULL_PATH_IN_LAUNCHER="\$WINEPREFIX/drive_c/users/$LINUX_USERNAME/AppData/Roaming/MesterMC/MesterMC.jar"
JAR_DIR_IN_LAUNCHER="\$(dirname "\$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER")"

echo "MesterMC indítása a következő Wine előtaggal: \$WINEPREFIX"

# Győződjön meg róla, hogy a .jar fájl létezik, mielőtt megpróbálná futtatni.
if [ ! -f "\$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER" ]; then
    echo "Hiba: A MesterMC.jar nem található a következő helyen: \$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER."
    echo "Kérjük, győződjön meg róla, hogy a MesterMC helyesen lett telepítve a Wine előtagon belül."
    exit 1
fi

# Váltson arra a könyvtárra, ahol a .jar található, mielőtt végrehajtaná.
# Ez néha megakadályozhatja a Java alkalmazáson belüli relatív útvonalakkal kapcsolatos problémákat.
cd "\$JAR_DIR_IN_LAUNCHER" || { echo "Hiba: Nem sikerült a könyvtárra váltani: \$JAR_DIR_IN_LAUNCHER"; exit 1; }

# MesterMC.jar futtatása Java segítségével.
# A 'java -jar' paranccsal futtatunk egy JAR fájlt.
java -jar "\$MESTERMC_JAR_FULL_PATH_IN_LAUNCHER"
EOF

    chmod +x "$LAUNCHER_SCRIPT_NAME" # Futtatási engedélyek hozzáadása
    echo "A **MesterMC** indító szkript '**$LAUNCHER_SCRIPT_NAME**' sikeresen létrejött!"
    echo "Most már futtathatja a **MesterMC**-t a terminálból a következő paranccsal: **./$LAUNCHER_SCRIPT_NAME**"

elif [ "$LAUNCHER_TYPE_CHOSEN" == "desktop" ]; then
    # Asztali indító fájl generálása (.desktop fájl)
    LAUNCHER_DESKTOP_NAME="MesterMC.desktop"
    GENERATED_LAUNCHER_FILE="$LAUNCHER_DESKTOP_NAME"
    echo "MesterMC asztali indító fájl generálása: $LAUNCHER_DESKTOP_NAME"

    cat <<EOF > "$LAUNCHER_DESKTOP_NAME"
[Desktop Entry]
Name=MesterMC
Comment=Játssz MesterMC-t Wine-on keresztül
Exec=env WINEPREFIX="$SELECTED_WINE_PREFIX" /usr/bin/java -jar "$MESTERMC_JAR_FULL_PATH"
Icon=$ICON_FULL_PATH
Terminal=false
Type=Application
Categories=Game;Minecraft;
StartupNotify=true
EOF

    chmod +x "$LAUNCHER_DESKTOP_NAME" # Futtatási engedélyek hozzáadása
    echo "A **MesterMC** asztali indító fájl '**$LAUNCHER_DESKTOP_NAME**' sikeresen létrejött!"

    read -p "Szeretné áthelyezni a '$LAUNCHER_DESKTOP_NAME' fájlt az alkalmazásmenübe való megjelenítéshez? (i/n): " MOVE_DESKTOP_CHOICE
    if [[ "$MOVE_DESKTOP_CHOICE" =~ ^[iI]$ ]]; then
        mkdir -p "$HOME/.local/share/applications" # Létrehozza a szükséges könyvtárat, ha még nincs.
        mv "$LAUNCHER_DESKTOP_NAME" "$HOME/.local/share/applications/"
        GENERATED_LAUNCHER_FILE="$HOME/.local/share/applications/$LAUNCHER_DESKTOP_NAME" # Frissítjük az útvonalat a takarításhoz, ha később szükség van rá.
        echo "Az indító fájl áthelyezve ide: **$HOME/.local/share/applications/**"
        echo "Lehet, hogy újra kell indítania a grafikus felületet, vagy ki-be kell jelentkeznie, hogy megjelenjen az alkalmazásmenüben."
    else
        echo "Az indító fájl a jelenlegi könyvtárban maradt. Duplán kattintva is elindíthatja."
    fi
    echo "Most már elindíthatja a **MesterMC**-t az alkalmazásmenüből vagy duplán kattintva a '$LAUNCHER_DESKTOP_NAME' fájlra (ha az aktuális könyvtárban maradt)."
fi

echo ""
echo "A telepítési és beállítási szkript befejeződött!"

print_header "Takarítás"

# 7. Takarítás
# Eltávolítja az ideiglenesen letöltött telepítőfájlokat.
echo "Ideiglenes telepítőfájlok eltávolítása..."

if [ -f "$WRAPPER_INSTALLER" ]; then
    rm -f "$WRAPPER_INSTALLER"
    echo "$WRAPPER_INSTALLER eltávolítva."
fi

if [ -f "$MESTERMC_INSTALLER_FILENAME" ]; then
    rm -f "$MESTERMC_INSTALLER_FILENAME"
    echo "$MESTERMC_INSTALLER_FILENAME eltávolítva."
fi

# A telepítő által esetlegesen generált Windows parancsikonok eltávolítása.
if [ -f "MesterMC.ink" ]; then
    rm -f "MesterMC.ink"
    echo "MesterMC.ink eltávolítva."
fi

if [ -f "MesterMC.lnk" ]; then
    rm -f "MesterMC.lnk"
    echo "MesterMC.lnk eltávolítva."
fi

echo "A takarítás befejeződött."
echo ""
echo "Köszönjük, hogy használta a szkriptet a MesterMC telepítéséhez!"
echo "Ha bármilyen problémába ütközik, kérjük, ellenőrizze a hibaüzeneteket és a Wine/Java telepítését."