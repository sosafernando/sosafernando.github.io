#!/bin/bash

# ==========================================
# Script Inteligente de Conversión MD a PDF
# Detecta dependencias, instala si falta y convierte
# ==========================================

# 1. Verificar argumentos
if [ -z "$1" ]; then
    echo "Uso: $0 <archivo.md>"
    exit 1
fi

INPUT_FILE="$1"
OUTPUT_FILE="${INPUT_FILE%.md}.pdf"

if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: El archivo '$INPUT_FILE' no existe."
    exit 1
fi

echo ">>> Analizando entorno para convertir '$INPUT_FILE'..."

# Función para instalar paquetes en Debian/Ubuntu/Pop!_OS
install_package() {
    local pkg=$1
    echo "   -> Instalando $pkg (requiere sudo)..."
    sudo apt update
    sudo apt install -y "$pkg"
    if [ $? -eq 0 ]; then
        echo "   -> ¡Instalación de $pkg exitosa!"
        return 0
    else
        echo "   -> Error instalando $pkg."
        return 1
    fi
}

# 2. Estrategia de Motor PDF
# Intentamos usar XeLaTeX (mejor calidad). Si no está, ofrecemos wkhtmltopdf.

ENGINE=""

# Verificar XeLaTeX
if command -v xelatex &> /dev/null; then
    echo "   -> Motor XeLaTeX detectado. (Calidad Tipográfica Alta)"
    ENGINE="xelatex"
else
    echo "   -> XeLaTeX no encontrado."
    
    # Verificar wkhtmltopdf como alternativa
    if command -v wkhtmltopdf &> /dev/null; then
        echo "   -> Motor wkhtmltopdf detectado. (Alternativa Ligera)"
        ENGINE="wkhtmltopdf"
    else
        echo "   -> Ningún motor PDF encontrado."
        echo "   -> ¿Desea instalar XeLaTeX (recomendado, ~200MB)? (s/n)"
        read -r response
        if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
            if install_package "texlive-xetex"; then
                ENGINE="xelatex"
            fi
        else
            echo "   -> ¿Desea instalar wkhtmltopdf (ligero, ~5MB)? (s/n)"
            read -r response
            if [[ "$response" =~ ^([sS][iI]|[sS])$ ]]; then
                if install_package "wkhtmltopdf"; then
                    ENGINE="wkhtmltopdf"
                fi
            fi
        fi
    fi
fi

# Si tras todo no hay motor, salir
if [ -z "$ENGINE" ]; then
    echo "ERROR: No se pudo configurar ningún motor de conversión. Saliendo."
    exit 1
fi

# 3. Ejecutar Conversión
echo ">>> Iniciando conversión con $ENGINE..."

if [ "$ENGINE" == "xelatex" ]; then
    pandoc "$INPUT_FILE" -o "$OUTPUT_FILE" \
        --pdf-engine=xelatex \
        -V geometry:margin=2.5cm \
        --highlight-style=kate \
        --toc
else
    # wkhtmltopdf no soporta la variable geometry de la misma forma
    pandoc "$INPUT_FILE" -o "$OUTPUT_FILE" \
        --pdf-engine=wkhtmltopdf \
        --highlight-style=kate \
        --toc
fi

# 4. Resultado Final
if [ $? -eq 0 ]; then
    echo "=========================================="
    echo "¡ÉXITO! PDF generado: $OUTPUT_FILE"
    echo "=========================================="
else
    echo "ERROR: La conversión falló incluso con el motor instalado."
    exit 1
fi   




