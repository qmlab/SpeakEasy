"""
Generate child-friendly SVG icons for task illustrations.

Each SVG is a simple, colorful icon suitable for children with autism.
Uses bold colors, simple shapes, and clear outlines.
"""

import os

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "images")
os.makedirs(OUTPUT_DIR, exist_ok=True)

# SVG template with rounded, child-friendly style
SVG_HEADER = '<?xml version="1.0" encoding="UTF-8"?>\n<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120" width="120" height="120">\n'
SVG_FOOTER = "</svg>\n"
BG_CIRCLE = (
    '<circle cx="60" cy="60" r="56" fill="{bg}" stroke="{stroke}" stroke-width="3"/>\n'
)


def make_svg(name: str, bg: str, stroke: str, inner: str):
    content = SVG_HEADER + BG_CIRCLE.format(bg=bg, stroke=stroke) + inner + SVG_FOOTER
    path = os.path.join(OUTPUT_DIR, f"{name}.svg")
    with open(path, "w") as f:
        f.write(content)
    return path


# ============================================================


def generate_all():
    """Generate all SVG icons. Only runs when called explicitly."""
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    # ANIMALS
    # ============================================================

    make_svg(
        "dog",
        "#FFF3E0",
        "#E65100",
        '<ellipse cx="60" cy="68" rx="22" ry="20" fill="#8D6E63"/>'
        '<circle cx="52" cy="62" r="3" fill="#fff"/><circle cx="68" cy="62" r="3" fill="#fff"/>'
        '<circle cx="52" cy="62" r="1.5" fill="#333"/><circle cx="68" cy="62" r="1.5" fill="#333"/>'
        '<ellipse cx="60" cy="72" rx="5" ry="3" fill="#333"/>'
        '<ellipse cx="42" cy="50" rx="8" ry="14" fill="#6D4C41" transform="rotate(-15 42 50)"/>'
        '<ellipse cx="78" cy="50" rx="8" ry="14" fill="#6D4C41" transform="rotate(15 78 50)"/>'
        '<path d="M55 78 Q60 83 65 78" stroke="#333" stroke-width="2" fill="none"/>',
    )

    make_svg(
        "cat",
        "#F3E5F5",
        "#7B1FA2",
        '<ellipse cx="60" cy="68" rx="20" ry="18" fill="#CE93D8"/>'
        '<polygon points="42,50 35,30 50,45" fill="#CE93D8" stroke="#7B1FA2" stroke-width="1.5"/>'
        '<polygon points="78,50 85,30 70,45" fill="#CE93D8" stroke="#7B1FA2" stroke-width="1.5"/>'
        '<circle cx="52" cy="62" r="3" fill="#fff"/><circle cx="68" cy="62" r="3" fill="#fff"/>'
        '<circle cx="52" cy="62" r="1.5" fill="#333"/><circle cx="68" cy="62" r="1.5" fill="#333"/>'
        '<ellipse cx="60" cy="70" rx="3" ry="2" fill="#E91E63"/>'
        '<line x1="35" y1="65" x2="48" y2="67" stroke="#7B1FA2" stroke-width="1"/>'
        '<line x1="35" y1="70" x2="48" y2="70" stroke="#7B1FA2" stroke-width="1"/>'
        '<line x1="72" y1="67" x2="85" y2="65" stroke="#7B1FA2" stroke-width="1"/>'
        '<line x1="72" y1="70" x2="85" y2="70" stroke="#7B1FA2" stroke-width="1"/>',
    )

    make_svg(
        "bird",
        "#E3F2FD",
        "#1565C0",
        '<ellipse cx="60" cy="65" rx="18" ry="16" fill="#64B5F6"/>'
        '<circle cx="53" cy="60" r="2.5" fill="#fff"/><circle cx="53" cy="60" r="1.2" fill="#333"/>'
        '<polygon points="65,62 80,58 65,66" fill="#FF9800"/>'
        '<path d="M42 65 Q30 55 25 65" stroke="#1565C0" stroke-width="2.5" fill="#42A5F5"/>'
        '<path d="M55 80 L60 88 L65 80" fill="#FF9800"/>',
    )

    make_svg(
        "fish",
        "#E0F7FA",
        "#00838F",
        '<ellipse cx="58" cy="60" rx="25" ry="15" fill="#4DD0E1"/>'
        '<polygon points="82,60 98,45 98,75" fill="#26C6DA"/>'
        '<circle cx="45" cy="56" r="3" fill="#fff"/><circle cx="45" cy="56" r="1.5" fill="#333"/>'
        '<path d="M60 65 Q65 70 70 65" stroke="#00838F" stroke-width="1.5" fill="none"/>',
    )

    make_svg(
        "rabbit",
        "#FFF8E1",
        "#F57F17",
        '<ellipse cx="60" cy="72" rx="18" ry="16" fill="#FFF9C4"/>'
        '<ellipse cx="50" cy="40" rx="7" ry="22" fill="#FFF9C4" stroke="#F57F17" stroke-width="1.5"/>'
        '<ellipse cx="70" cy="40" rx="7" ry="22" fill="#FFF9C4" stroke="#F57F17" stroke-width="1.5"/>'
        '<ellipse cx="50" cy="40" rx="4" ry="16" fill="#FFCDD2"/>'
        '<ellipse cx="70" cy="40" rx="4" ry="16" fill="#FFCDD2"/>'
        '<circle cx="53" cy="66" r="2.5" fill="#333"/><circle cx="67" cy="66" r="2.5" fill="#333"/>'
        '<ellipse cx="60" cy="74" rx="3" ry="2" fill="#E91E63"/>',
    )

    make_svg(
        "butterfly",
        "#FCE4EC",
        "#AD1457",
        '<ellipse cx="60" cy="60" rx="3" ry="15" fill="#5D4037"/>'
        '<ellipse cx="45" cy="52" rx="15" ry="12" fill="#F48FB1" stroke="#AD1457" stroke-width="1.5"/>'
        '<ellipse cx="75" cy="52" rx="15" ry="12" fill="#CE93D8" stroke="#7B1FA2" stroke-width="1.5"/>'
        '<ellipse cx="45" cy="70" rx="12" ry="10" fill="#CE93D8" stroke="#7B1FA2" stroke-width="1.5"/>'
        '<ellipse cx="75" cy="70" rx="12" ry="10" fill="#F48FB1" stroke="#AD1457" stroke-width="1.5"/>'
        '<circle cx="45" cy="52" r="4" fill="#E91E63" opacity="0.5"/>'
        '<circle cx="75" cy="52" r="4" fill="#9C27B0" opacity="0.5"/>'
        '<line x1="57" y1="45" x2="50" y2="35" stroke="#5D4037" stroke-width="1.5"/>'
        '<line x1="63" y1="45" x2="70" y2="35" stroke="#5D4037" stroke-width="1.5"/>'
        '<circle cx="50" cy="34" r="2" fill="#5D4037"/><circle cx="70" cy="34" r="2" fill="#5D4037"/>',
    )

    make_svg(
        "duck",
        "#FFFDE7",
        "#F9A825",
        '<ellipse cx="60" cy="68" rx="22" ry="18" fill="#FFD54F"/>'
        '<circle cx="55" cy="52" r="14" fill="#FFD54F"/>'
        '<circle cx="50" cy="49" r="2.5" fill="#333"/>'
        '<polygon points="40,55 25,52 40,58" fill="#FF9800"/>'
        '<path d="M70 80 L75 90 M55 82 L52 92" stroke="#FF9800" stroke-width="3"/>',
    )

    make_svg(
        "elephant",
        "#ECEFF1",
        "#546E7A",
        '<ellipse cx="60" cy="65" rx="25" ry="22" fill="#90A4AE"/>'
        '<circle cx="48" cy="55" r="3" fill="#fff"/><circle cx="48" cy="55" r="1.5" fill="#333"/>'
        '<path d="M75 60 Q85 65 80 80 Q78 85 75 80 Q72 75 74 65" fill="#90A4AE" stroke="#546E7A" stroke-width="1.5"/>'
        '<ellipse cx="40" cy="58" rx="10" ry="12" fill="#78909C"/>'
        '<ellipse cx="80" cy="58" rx="10" ry="12" fill="#78909C"/>',
    )

    make_svg(
        "penguin",
        "#E8EAF6",
        "#283593",
        '<ellipse cx="60" cy="65" rx="20" ry="25" fill="#37474F"/>'
        '<ellipse cx="60" cy="70" rx="13" ry="18" fill="#fff"/>'
        '<circle cx="53" cy="52" r="2.5" fill="#fff"/><circle cx="67" cy="52" r="2.5" fill="#fff"/>'
        '<circle cx="53" cy="52" r="1.2" fill="#333"/><circle cx="67" cy="52" r="1.2" fill="#333"/>'
        '<polygon points="57,58 60,63 63,58" fill="#FF9800"/>'
        '<path d="M40 60 Q35 70 42 80" stroke="#37474F" stroke-width="4" fill="none"/>'
        '<path d="M80 60 Q85 70 78 80" stroke="#37474F" stroke-width="4" fill="none"/>'
        '<path d="M52 88 L48 93 L58 93 Z" fill="#FF9800"/>'
        '<path d="M68 88 L62 93 L72 93 Z" fill="#FF9800"/>',
    )

    make_svg(
        "frog",
        "#E8F5E9",
        "#2E7D32",
        '<ellipse cx="60" cy="68" rx="22" ry="16" fill="#66BB6A"/>'
        '<circle cx="48" cy="50" r="10" fill="#66BB6A"/><circle cx="72" cy="50" r="10" fill="#66BB6A"/>'
        '<circle cx="48" cy="48" r="5" fill="#fff"/><circle cx="72" cy="48" r="5" fill="#fff"/>'
        '<circle cx="48" cy="48" r="2.5" fill="#333"/><circle cx="72" cy="48" r="2.5" fill="#333"/>'
        '<path d="M52 75 Q60 80 68 75" stroke="#2E7D32" stroke-width="2" fill="none"/>',
    )

    make_svg(
        "bear",
        "#EFEBE9",
        "#4E342E",
        '<circle cx="60" cy="65" r="22" fill="#8D6E63"/>'
        '<circle cx="42" cy="45" r="9" fill="#8D6E63"/><circle cx="78" cy="45" r="9" fill="#8D6E63"/>'
        '<circle cx="42" cy="45" r="5" fill="#6D4C41"/><circle cx="78" cy="45" r="5" fill="#6D4C41"/>'
        '<circle cx="52" cy="60" r="3" fill="#fff"/><circle cx="68" cy="60" r="3" fill="#fff"/>'
        '<circle cx="52" cy="60" r="1.5" fill="#333"/><circle cx="68" cy="60" r="1.5" fill="#333"/>'
        '<ellipse cx="60" cy="70" rx="5" ry="3" fill="#333"/>',
    )

    make_svg(
        "whale",
        "#E3F2FD",
        "#0D47A1",
        '<ellipse cx="58" cy="62" rx="30" ry="20" fill="#42A5F5"/>'
        '<circle cx="42" cy="55" r="3" fill="#fff"/><circle cx="42" cy="55" r="1.5" fill="#333"/>'
        '<path d="M85 55 Q95 40 100 50 Q95 45 90 55" fill="#42A5F5"/>'
        '<path d="M55 80 Q58 82 62 80" stroke="#0D47A1" stroke-width="1.5" fill="none"/>'
        '<path d="M50 42 Q52 32 55 42" stroke="#42A5F5" stroke-width="3" fill="none"/>',
    )

    make_svg(
        "dolphin",
        "#E1F5FE",
        "#01579B",
        '<path d="M30 65 Q45 45 70 50 Q90 55 95 60 Q90 65 85 62 Q75 75 50 75 Q35 75 30 65Z" fill="#4FC3F7"/>'
        '<circle cx="45" cy="58" r="2" fill="#333"/>'
        '<path d="M80 50 Q85 40 90 48" fill="#4FC3F7"/>',
    )

    # ============================================================
    # FOOD
    # ============================================================

    make_svg(
        "apple",
        "#FFEBEE",
        "#C62828",
        '<circle cx="60" cy="65" r="22" fill="#EF5350"/>'
        '<path d="M60 43 Q62 30 68 35" stroke="#4CAF50" stroke-width="2.5" fill="none"/>'
        '<ellipse cx="65" cy="38" rx="6" ry="4" fill="#4CAF50" transform="rotate(30 65 38)"/>'
        '<path d="M50 55 Q55 50 60 55" fill="#fff" opacity="0.3"/>',
    )

    make_svg(
        "banana",
        "#FFFDE7",
        "#F9A825",
        '<path d="M40 80 Q30 50 50 35 Q60 28 70 35 Q55 50 50 80Z" fill="#FDD835" stroke="#F9A825" stroke-width="2"/>'
        '<path d="M50 35 Q55 30 60 33" stroke="#8D6E63" stroke-width="2" fill="none"/>',
    )

    make_svg(
        "orange",
        "#FFF3E0",
        "#E65100",
        '<circle cx="60" cy="65" r="22" fill="#FF9800"/>'
        '<circle cx="60" cy="44" r="3" fill="#4CAF50"/>'
        '<path d="M60 44 Q62 38 65 40" stroke="#4CAF50" stroke-width="1.5" fill="none"/>'
        '<path d="M48 60 Q55 55 62 60" fill="#FB8C00" opacity="0.3"/>',
    )

    make_svg(
        "grape",
        "#F3E5F5",
        "#6A1B9A",
        '<circle cx="52" cy="55" r="8" fill="#9C27B0"/><circle cx="68" cy="55" r="8" fill="#9C27B0"/>'
        '<circle cx="60" cy="55" r="8" fill="#AB47BC"/>'
        '<circle cx="48" cy="67" r="8" fill="#9C27B0"/><circle cx="72" cy="67" r="8" fill="#9C27B0"/>'
        '<circle cx="60" cy="67" r="8" fill="#AB47BC"/>'
        '<circle cx="55" cy="78" r="8" fill="#9C27B0"/><circle cx="65" cy="78" r="8" fill="#9C27B0"/>'
        '<path d="M60 47 Q62 38 65 42" stroke="#4CAF50" stroke-width="2" fill="none"/>',
    )

    make_svg(
        "strawberry",
        "#FFEBEE",
        "#B71C1C",
        '<path d="M45 55 Q60 90 75 55 Q60 40 45 55Z" fill="#E53935"/>'
        '<circle cx="55" cy="60" r="1.5" fill="#FFEB3B"/><circle cx="65" cy="60" r="1.5" fill="#FFEB3B"/>'
        '<circle cx="60" cy="68" r="1.5" fill="#FFEB3B"/><circle cx="55" cy="75" r="1.5" fill="#FFEB3B"/>'
        '<circle cx="65" cy="75" r="1.5" fill="#FFEB3B"/>'
        '<ellipse cx="55" cy="48" rx="6" ry="3" fill="#4CAF50" transform="rotate(-20 55 48)"/>'
        '<ellipse cx="65" cy="48" rx="6" ry="3" fill="#4CAF50" transform="rotate(20 65 48)"/>',
    )

    make_svg(
        "watermelon",
        "#E8F5E9",
        "#1B5E20",
        '<path d="M30 70 Q60 20 90 70Z" fill="#4CAF50" stroke="#1B5E20" stroke-width="2"/>'
        '<path d="M35 68 Q60 28 85 68Z" fill="#EF5350"/>'
        '<circle cx="50" cy="58" r="2" fill="#333"/><circle cx="60" cy="52" r="2" fill="#333"/>'
        '<circle cx="70" cy="58" r="2" fill="#333"/><circle cx="55" cy="64" r="2" fill="#333"/>'
        '<circle cx="65" cy="64" r="2" fill="#333"/>',
    )

    make_svg(
        "pear",
        "#F1F8E9",
        "#33691E",
        '<circle cx="60" cy="72" r="18" fill="#C5E1A5"/>'
        '<ellipse cx="60" cy="52" rx="12" ry="14" fill="#C5E1A5"/>'
        '<path d="M60 38 Q63 30 66 34" stroke="#795548" stroke-width="2" fill="none"/>'
        '<ellipse cx="64" cy="32" rx="5" ry="3" fill="#4CAF50" transform="rotate(20 64 32)"/>',
    )

    make_svg(
        "cake",
        "#FFF8E1",
        "#FF6F00",
        '<rect x="35" y="60" width="50" height="25" rx="5" fill="#FFCC80"/>'
        '<rect x="32" y="55" width="56" height="10" rx="5" fill="#FF7043"/>'
        '<rect x="35" y="50" width="50" height="8" rx="4" fill="#FFAB91"/>'
        '<rect x="57" y="30" width="6" height="22" rx="3" fill="#FFD54F"/>'
        '<ellipse cx="60" cy="28" rx="4" ry="5" fill="#FF9800"/>'
        '<circle cx="60" cy="25" r="2" fill="#FFEB3B"/>',
    )

    make_svg(
        "pizza",
        "#FFF8E1",
        "#E65100",
        '<path d="M35 80 L60 30 L85 80Z" fill="#FFC107" stroke="#E65100" stroke-width="2"/>'
        '<circle cx="52" cy="60" r="5" fill="#E53935"/><circle cx="68" cy="60" r="5" fill="#E53935"/>'
        '<circle cx="60" cy="70" r="5" fill="#E53935"/>'
        '<circle cx="55" cy="68" r="3" fill="#4CAF50"/><circle cx="65" cy="55" r="3" fill="#4CAF50"/>',
    )

    make_svg(
        "ice_cream",
        "#FCE4EC",
        "#880E4F",
        '<polygon points="50,65 60,95 70,65" fill="#FFCC80" stroke="#E65100" stroke-width="1.5"/>'
        '<circle cx="60" cy="55" r="18" fill="#F48FB1"/>'
        '<circle cx="50" cy="48" r="10" fill="#CE93D8"/>'
        '<circle cx="70" cy="48" r="10" fill="#81D4FA"/>'
        '<circle cx="60" cy="42" r="3" fill="#FF5252"/>',
    )

    make_svg(
        "bread",
        "#FFF8E1",
        "#BF360C",
        '<ellipse cx="60" cy="65" rx="28" ry="18" fill="#FFCC80"/>'
        '<ellipse cx="60" cy="58" rx="24" ry="12" fill="#FFB74D"/>'
        '<path d="M40 58 Q50 50 60 53 Q70 50 80 58" fill="#FFA726"/>',
    )

    make_svg(
        "milk",
        "#E3F2FD",
        "#1565C0",
        '<rect x="42" y="42" width="36" height="45" rx="4" fill="#fff" stroke="#1565C0" stroke-width="2"/>'
        '<rect x="42" y="42" width="36" height="15" rx="4" fill="#2196F3"/>'
        '<rect x="50" y="35" width="20" height="12" rx="3" fill="#2196F3"/>'
        '<text x="60" y="72" text-anchor="middle" font-size="12" fill="#1565C0" font-weight="bold">MILK</text>',
    )

    make_svg(
        "cookie",
        "#EFEBE9",
        "#4E342E",
        '<circle cx="60" cy="60" r="22" fill="#D7CCC8"/>'
        '<circle cx="50" cy="52" r="3" fill="#5D4037"/><circle cx="68" cy="55" r="3" fill="#5D4037"/>'
        '<circle cx="55" cy="68" r="3" fill="#5D4037"/><circle cx="70" cy="68" r="2.5" fill="#5D4037"/>'
        '<circle cx="60" cy="58" r="2.5" fill="#5D4037"/>',
    )

    # ============================================================
    # VEHICLES
    # ============================================================

    make_svg(
        "car",
        "#E3F2FD",
        "#1565C0",
        '<rect x="30" y="55" width="60" height="22" rx="8" fill="#F44336"/>'
        '<path d="M42 55 Q45 38 60 38 Q75 38 78 55" fill="#EF5350"/>'
        '<rect x="48" y="42" width="10" height="13" rx="2" fill="#BBDEFB"/>'
        '<rect x="62" y="42" width="12" height="13" rx="2" fill="#BBDEFB"/>'
        '<circle cx="42" cy="80" r="7" fill="#333"/><circle cx="42" cy="80" r="3" fill="#666"/>'
        '<circle cx="78" cy="80" r="7" fill="#333"/><circle cx="78" cy="80" r="3" fill="#666"/>',
    )

    make_svg(
        "bus",
        "#FFF8E1",
        "#F57F17",
        '<rect x="25" y="45" width="70" height="32" rx="6" fill="#FDD835"/>'
        '<rect x="30" y="50" width="14" height="12" rx="2" fill="#BBDEFB"/>'
        '<rect x="48" y="50" width="14" height="12" rx="2" fill="#BBDEFB"/>'
        '<rect x="66" y="50" width="14" height="12" rx="2" fill="#BBDEFB"/>'
        '<circle cx="38" cy="80" r="6" fill="#333"/><circle cx="38" cy="80" r="3" fill="#666"/>'
        '<circle cx="82" cy="80" r="6" fill="#333"/><circle cx="82" cy="80" r="3" fill="#666"/>',
    )

    make_svg(
        "truck",
        "#ECEFF1",
        "#37474F",
        '<rect x="20" y="50" width="50" height="28" rx="4" fill="#78909C"/>'
        '<rect x="72" y="55" width="25" height="23" rx="4" fill="#546E7A"/>'
        '<rect x="76" y="58" width="16" height="12" rx="2" fill="#BBDEFB"/>'
        '<circle cx="35" cy="82" r="6" fill="#333"/><circle cx="55" cy="82" r="6" fill="#333"/>'
        '<circle cx="85" cy="82" r="6" fill="#333"/>',
    )

    make_svg(
        "airplane",
        "#E8EAF6",
        "#283593",
        '<ellipse cx="60" cy="60" rx="30" ry="8" fill="#5C6BC0"/>'
        '<polygon points="30,60 20,40 40,55" fill="#3F51B5"/>'
        '<polygon points="30,60 20,80 40,65" fill="#3F51B5"/>'
        '<polygon points="75,60 90,48 90,60" fill="#3F51B5"/>'
        '<polygon points="75,60 90,72 90,60" fill="#3F51B5"/>'
        '<circle cx="35" cy="57" r="3" fill="#BBDEFB"/>'
        '<circle cx="45" cy="57" r="3" fill="#BBDEFB"/>'
        '<circle cx="55" cy="57" r="3" fill="#BBDEFB"/>',
    )

    make_svg(
        "boat",
        "#E0F7FA",
        "#006064",
        '<path d="M25 70 L35 85 L85 85 L95 70Z" fill="#795548"/>'
        '<rect x="55" y="40" width="5" height="30" fill="#795548"/>'
        '<polygon points="60,40 60,65 85,65" fill="#fff" stroke="#E0E0E0" stroke-width="1"/>'
        '<path d="M20 90 Q40 82 60 90 Q80 82 100 90" fill="none" stroke="#4DD0E1" stroke-width="3"/>',
    )

    make_svg(
        "train",
        "#F3E5F5",
        "#4A148C",
        '<rect x="25" y="50" width="70" height="28" rx="5" fill="#7B1FA2"/>'
        '<rect x="30" y="55" width="12" height="10" rx="2" fill="#BBDEFB"/>'
        '<rect x="46" y="55" width="12" height="10" rx="2" fill="#BBDEFB"/>'
        '<rect x="62" y="55" width="12" height="10" rx="2" fill="#BBDEFB"/>'
        '<circle cx="35" cy="82" r="6" fill="#333"/><circle cx="55" cy="82" r="6" fill="#333"/>'
        '<circle cx="75" cy="82" r="6" fill="#333"/>'
        '<rect x="80" y="38" width="8" height="15" rx="3" fill="#7B1FA2"/>'
        '<ellipse cx="84" cy="35" rx="6" ry="4" fill="#B0BEC5"/>',
    )

    make_svg(
        "bicycle",
        "#E8F5E9",
        "#1B5E20",
        '<circle cx="38" cy="70" r="14" fill="none" stroke="#4CAF50" stroke-width="3"/>'
        '<circle cx="82" cy="70" r="14" fill="none" stroke="#4CAF50" stroke-width="3"/>'
        '<line x1="38" y1="70" x2="60" y2="50" stroke="#333" stroke-width="2.5"/>'
        '<line x1="60" y1="50" x2="82" y2="70" stroke="#333" stroke-width="2.5"/>'
        '<line x1="60" y1="50" x2="55" y2="42" stroke="#333" stroke-width="2.5"/>'
        '<line x1="50" y1="42" x2="62" y2="42" stroke="#333" stroke-width="3"/>',
    )

    # ============================================================
    # NATURE
    # ============================================================

    make_svg(
        "sun",
        "#FFF8E1",
        "#FF6F00",
        '<circle cx="60" cy="60" r="18" fill="#FDD835"/>'
        '<line x1="60" y1="30" x2="60" y2="20" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="60" y1="100" x2="60" y2="90" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="30" y1="60" x2="20" y2="60" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="100" y1="60" x2="90" y2="60" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="38" y1="38" x2="31" y2="31" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="82" y1="38" x2="89" y2="31" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="38" y1="82" x2="31" y2="89" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>'
        '<line x1="82" y1="82" x2="89" y2="89" stroke="#FDD835" stroke-width="4" stroke-linecap="round"/>',
    )

    make_svg(
        "moon",
        "#F3E5F5",
        "#4A148C",
        '<circle cx="60" cy="60" r="22" fill="#FDD835"/>'
        '<circle cx="72" cy="52" r="18" fill="#F3E5F5"/>'
        '<circle cx="50" cy="55" r="2" fill="#FBC02D"/>'
        '<circle cx="55" cy="68" r="1.5" fill="#FBC02D"/>'
        '<circle cx="62" cy="72" r="2.5" fill="#FBC02D"/>',
    )

    make_svg(
        "star",
        "#FFF8E1",
        "#FF6F00",
        '<polygon points="60,25 68,50 95,50 73,65 80,90 60,75 40,90 47,65 25,50 52,50" fill="#FDD835" stroke="#FF6F00" stroke-width="2"/>',
    )

    make_svg(
        "tree",
        "#E8F5E9",
        "#1B5E20",
        '<rect x="55" y="70" width="10" height="25" rx="2" fill="#795548"/>'
        '<circle cx="60" cy="50" r="25" fill="#4CAF50"/>'
        '<circle cx="48" cy="58" r="15" fill="#66BB6A"/>'
        '<circle cx="72" cy="58" r="15" fill="#66BB6A"/>'
        '<circle cx="60" cy="42" r="12" fill="#81C784"/>',
    )

    make_svg(
        "flower",
        "#FCE4EC",
        "#AD1457",
        '<rect x="57" y="65" width="6" height="30" fill="#4CAF50"/>'
        '<ellipse cx="45" cy="75" rx="8" ry="4" fill="#4CAF50" transform="rotate(-30 45 75)"/>'
        '<circle cx="60" cy="55" r="8" fill="#FDD835"/>'
        '<circle cx="48" cy="48" r="8" fill="#F48FB1"/><circle cx="72" cy="48" r="8" fill="#F48FB1"/>'
        '<circle cx="48" cy="62" r="8" fill="#F48FB1"/><circle cx="72" cy="62" r="8" fill="#F48FB1"/>'
        '<circle cx="45" cy="55" r="8" fill="#EC407A"/><circle cx="75" cy="55" r="8" fill="#EC407A"/>',
    )

    make_svg(
        "cloud",
        "#ECEFF1",
        "#546E7A",
        '<circle cx="50" cy="60" r="18" fill="#fff"/>'
        '<circle cx="70" cy="60" r="15" fill="#fff"/>'
        '<circle cx="60" cy="50" r="16" fill="#fff"/>'
        '<circle cx="42" cy="55" r="12" fill="#fff"/>'
        '<circle cx="78" cy="58" r="10" fill="#fff"/>',
    )

    make_svg(
        "rainbow",
        "#F3E5F5",
        "#7B1FA2",
        '<path d="M20 80 Q60 10 100 80" fill="none" stroke="#F44336" stroke-width="5"/>'
        '<path d="M25 80 Q60 18 95 80" fill="none" stroke="#FF9800" stroke-width="5"/>'
        '<path d="M30 80 Q60 26 90 80" fill="none" stroke="#FFEB3B" stroke-width="5"/>'
        '<path d="M35 80 Q60 34 85 80" fill="none" stroke="#4CAF50" stroke-width="5"/>'
        '<path d="M40 80 Q60 42 80 80" fill="none" stroke="#2196F3" stroke-width="5"/>'
        '<path d="M45 80 Q60 50 75 80" fill="none" stroke="#9C27B0" stroke-width="5"/>',
    )

    make_svg(
        "rain",
        "#E3F2FD",
        "#0D47A1",
        '<circle cx="55" cy="45" r="14" fill="#90A4AE"/>'
        '<circle cx="70" cy="45" r="11" fill="#90A4AE"/>'
        '<circle cx="45" cy="48" r="10" fill="#90A4AE"/>'
        '<path d="M40 62 L38 72" stroke="#42A5F5" stroke-width="2.5" stroke-linecap="round"/>'
        '<path d="M50 65 L48 78" stroke="#42A5F5" stroke-width="2.5" stroke-linecap="round"/>'
        '<path d="M60 62 L58 75" stroke="#42A5F5" stroke-width="2.5" stroke-linecap="round"/>'
        '<path d="M70 65 L68 78" stroke="#42A5F5" stroke-width="2.5" stroke-linecap="round"/>'
        '<path d="M80 62 L78 72" stroke="#42A5F5" stroke-width="2.5" stroke-linecap="round"/>',
    )

    make_svg(
        "snowman",
        "#ECEFF1",
        "#455A64",
        '<circle cx="60" cy="78" r="18" fill="#fff" stroke="#B0BEC5" stroke-width="1.5"/>'
        '<circle cx="60" cy="52" r="14" fill="#fff" stroke="#B0BEC5" stroke-width="1.5"/>'
        '<circle cx="60" cy="32" r="10" fill="#fff" stroke="#B0BEC5" stroke-width="1.5"/>'
        '<circle cx="56" cy="30" r="2" fill="#333"/><circle cx="64" cy="30" r="2" fill="#333"/>'
        '<polygon points="60,34 70,36 60,38" fill="#FF9800"/>'
        '<rect x="48" y="22" width="24" height="5" rx="2" fill="#333"/>'
        '<rect x="52" y="15" width="16" height="10" rx="2" fill="#333"/>',
    )

    # ============================================================
    # HOUSEHOLD & SCHOOL
    # ============================================================

    make_svg(
        "cup",
        "#E3F2FD",
        "#1565C0",
        '<path d="M38 45 L42 85 L78 85 L82 45Z" fill="#42A5F5" stroke="#1565C0" stroke-width="2"/>'
        '<path d="M82 55 Q95 55 95 65 Q95 75 82 75" fill="none" stroke="#1565C0" stroke-width="3"/>'
        '<ellipse cx="60" cy="45" rx="22" ry="5" fill="#64B5F6" stroke="#1565C0" stroke-width="2"/>',
    )

    make_svg(
        "spoon",
        "#FFF8E1",
        "#827717",
        '<ellipse cx="60" cy="45" rx="12" ry="16" fill="#BDBDBD" stroke="#757575" stroke-width="1.5"/>'
        '<rect x="57" y="58" width="6" height="35" rx="3" fill="#BDBDBD" stroke="#757575" stroke-width="1.5"/>',
    )

    make_svg(
        "plate",
        "#FAFAFA",
        "#9E9E9E",
        '<ellipse cx="60" cy="65" rx="30" ry="12" fill="#fff" stroke="#BDBDBD" stroke-width="2"/>'
        '<ellipse cx="60" cy="65" rx="20" ry="8" fill="none" stroke="#E0E0E0" stroke-width="1.5"/>',
    )

    make_svg(
        "book",
        "#E8EAF6",
        "#283593",
        '<rect x="32" y="35" width="56" height="50" rx="3" fill="#5C6BC0"/>'
        '<rect x="35" y="38" width="25" height="44" rx="2" fill="#7986CB"/>'
        '<rect x="62" y="38" width="23" height="44" rx="2" fill="#fff"/>'
        '<line x1="60" y1="35" x2="60" y2="85" stroke="#3949AB" stroke-width="3"/>'
        '<line x1="66" y1="50" x2="80" y2="50" stroke="#C5CAE9" stroke-width="1.5"/>'
        '<line x1="66" y1="56" x2="80" y2="56" stroke="#C5CAE9" stroke-width="1.5"/>'
        '<line x1="66" y1="62" x2="78" y2="62" stroke="#C5CAE9" stroke-width="1.5"/>',
    )

    make_svg(
        "pencil",
        "#FFF8E1",
        "#F57F17",
        '<rect x="55" y="25" width="10" height="55" rx="2" fill="#FDD835"/>'
        '<polygon points="55,80 60,95 65,80" fill="#FFCC80"/>'
        '<rect x="55" y="25" width="10" height="8" rx="2" fill="#E91E63"/>'
        '<line x1="60" y1="90" x2="60" y2="95" stroke="#333" stroke-width="1"/>',
    )

    make_svg(
        "scissors",
        "#FCE4EC",
        "#C62828",
        '<ellipse cx="45" cy="42" rx="10" ry="8" fill="none" stroke="#F44336" stroke-width="3"/>'
        '<ellipse cx="75" cy="42" rx="10" ry="8" fill="none" stroke="#F44336" stroke-width="3"/>'
        '<line x1="52" y1="48" x2="68" y2="85" stroke="#BDBDBD" stroke-width="3"/>'
        '<line x1="68" y1="48" x2="52" y2="85" stroke="#BDBDBD" stroke-width="3"/>',
    )

    make_svg(
        "clock",
        "#FFF8E1",
        "#E65100",
        '<circle cx="60" cy="60" r="25" fill="#fff" stroke="#333" stroke-width="3"/>'
        '<circle cx="60" cy="60" r="2" fill="#333"/>'
        '<line x1="60" y1="60" x2="60" y2="42" stroke="#333" stroke-width="2.5"/>'
        '<line x1="60" y1="60" x2="75" y2="60" stroke="#333" stroke-width="2"/>'
        '<text x="60" y="42" text-anchor="middle" font-size="7" fill="#333">12</text>'
        '<text x="82" y="63" text-anchor="middle" font-size="7" fill="#333">3</text>'
        '<text x="60" y="83" text-anchor="middle" font-size="7" fill="#333">6</text>'
        '<text x="38" y="63" text-anchor="middle" font-size="7" fill="#333">9</text>',
    )

    make_svg(
        "lamp",
        "#FFF8E1",
        "#FF6F00",
        '<polygon points="42,70 60,35 78,70" fill="#FDD835"/>'
        '<rect x="50" y="70" width="20" height="5" rx="2" fill="#795548"/>'
        '<rect x="55" y="75" width="10" height="12" rx="2" fill="#8D6E63"/>'
        '<ellipse cx="60" cy="33" rx="5" ry="3" fill="#FFE082"/>',
    )

    make_svg(
        "umbrella",
        "#E1F5FE",
        "#01579B",
        '<path d="M30 60 Q60 20 90 60" fill="#2196F3" stroke="#1565C0" stroke-width="2"/>'
        '<line x1="60" y1="35" x2="60" y2="90" stroke="#795548" stroke-width="3"/>'
        '<path d="M60 90 Q55 95 52 90" stroke="#795548" stroke-width="3" fill="none"/>',
    )

    make_svg(
        "key",
        "#FFF8E1",
        "#F57F17",
        '<circle cx="45" cy="55" r="12" fill="none" stroke="#FDD835" stroke-width="5"/>'
        '<rect x="55" y="52" width="30" height="6" rx="2" fill="#FDD835"/>'
        '<rect x="78" y="52" width="5" height="12" rx="1" fill="#FDD835"/>'
        '<rect x="72" y="52" width="5" height="10" rx="1" fill="#FDD835"/>',
    )

    make_svg(
        "chair",
        "#EFEBE9",
        "#4E342E",
        '<rect x="40" y="35" width="5" height="55" rx="1" fill="#8D6E63"/>'
        '<rect x="75" y="35" width="5" height="55" rx="1" fill="#8D6E63"/>'
        '<rect x="40" y="60" width="40" height="5" rx="2" fill="#A1887F"/>'
        '<rect x="40" y="35" width="40" height="5" rx="2" fill="#A1887F"/>'
        '<rect x="40" y="65" width="5" height="25" rx="1" fill="#8D6E63"/>'
        '<rect x="75" y="65" width="5" height="25" rx="1" fill="#8D6E63"/>',
    )

    make_svg(
        "bed",
        "#FCE4EC",
        "#880E4F",
        '<rect x="25" y="55" width="70" height="25" rx="4" fill="#F48FB1"/>'
        '<rect x="25" y="40" width="20" height="40" rx="4" fill="#AD1457"/>'
        '<rect x="75" y="55" width="20" height="25" rx="4" fill="#AD1457"/>'
        '<rect x="28" y="58" width="64" height="8" rx="3" fill="#fff"/>'
        '<ellipse cx="38" cy="52" rx="10" ry="6" fill="#fff"/>',
    )

    make_svg(
        "house",
        "#FFF3E0",
        "#BF360C",
        '<rect x="35" y="55" width="50" height="35" rx="2" fill="#FFCC80"/>'
        '<polygon points="30,58 60,30 90,58" fill="#F44336" stroke="#C62828" stroke-width="2"/>'
        '<rect x="52" y="70" width="16" height="20" rx="2" fill="#795548"/>'
        '<circle cx="65" cy="80" r="2" fill="#FDD835"/>'
        '<rect x="40" y="62" width="10" height="10" rx="1" fill="#BBDEFB"/>'
        '<rect x="70" y="62" width="10" height="10" rx="1" fill="#BBDEFB"/>',
    )

    # ============================================================
    # CLOTHING
    # ============================================================

    make_svg(
        "hat",
        "#E8EAF6",
        "#283593",
        '<ellipse cx="60" cy="75" rx="30" ry="8" fill="#3F51B5"/>'
        '<rect x="42" y="45" width="36" height="30" rx="5" fill="#5C6BC0"/>'
        '<rect x="42" y="45" width="36" height="8" rx="3" fill="#283593"/>',
    )

    make_svg(
        "shoe",
        "#EFEBE9",
        "#3E2723",
        '<path d="M30 65 Q30 50 50 50 L80 50 Q95 50 95 60 L95 70 Q95 80 85 80 L40 80 Q30 80 30 65Z" fill="#5D4037"/>'
        '<path d="M30 65 Q30 55 50 55 L80 55 Q90 55 90 62" fill="#795548"/>'
        '<ellipse cx="42" cy="52" rx="4" ry="3" fill="#333"/>',
    )

    make_svg(
        "shirt",
        "#E3F2FD",
        "#1565C0",
        '<path d="M40 40 L30 55 L38 58 L42 48 L42 85 L78 85 L78 48 L82 58 L90 55 L80 40 L68 45 L60 40 L52 45Z" fill="#42A5F5" stroke="#1565C0" stroke-width="1.5"/>'
        '<circle cx="60" cy="55" r="2" fill="#1565C0"/>'
        '<circle cx="60" cy="65" r="2" fill="#1565C0"/>'
        '<circle cx="60" cy="75" r="2" fill="#1565C0"/>',
    )

    # ============================================================
    # TOYS
    # ============================================================

    make_svg(
        "ball",
        "#FFEBEE",
        "#C62828",
        '<circle cx="60" cy="60" r="24" fill="#F44336"/>'
        '<path d="M42 48 Q60 38 78 48" fill="none" stroke="#E53935" stroke-width="3"/>'
        '<path d="M42 72 Q60 82 78 72" fill="none" stroke="#E53935" stroke-width="3"/>'
        '<path d="M50 45 Q50 60 50 75" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.3"/>'
        '<path d="M70 45 Q70 60 70 75" fill="none" stroke="#fff" stroke-width="1.5" opacity="0.3"/>',
    )

    make_svg(
        "doll",
        "#FCE4EC",
        "#AD1457",
        '<circle cx="60" cy="42" r="14" fill="#FFCCBC"/>'
        '<circle cx="55" cy="40" r="2" fill="#333"/><circle cx="65" cy="40" r="2" fill="#333"/>'
        '<path d="M57 46 Q60 48 63 46" stroke="#E91E63" stroke-width="1.5" fill="none"/>'
        '<path d="M45 32 Q50 25 55 32" fill="#5D4037"/>'
        '<path d="M65 32 Q70 25 75 32" fill="#5D4037"/>'
        '<path d="M45 32 Q60 22 75 32" fill="#5D4037"/>'
        '<path d="M48 55 L45 90 L55 90 L58 65 L62 65 L65 90 L75 90 L72 55Z" fill="#E91E63"/>',
    )

    make_svg(
        "teddy_bear",
        "#EFEBE9",
        "#5D4037",
        '<circle cx="60" cy="65" r="20" fill="#D7CCC8"/>'
        '<circle cx="60" cy="42" r="15" fill="#D7CCC8"/>'
        '<circle cx="45" cy="32" r="8" fill="#D7CCC8"/><circle cx="75" cy="32" r="8" fill="#D7CCC8"/>'
        '<circle cx="45" cy="32" r="4" fill="#BCAAA4"/><circle cx="75" cy="32" r="4" fill="#BCAAA4"/>'
        '<circle cx="54" cy="40" r="2.5" fill="#333"/><circle cx="66" cy="40" r="2.5" fill="#333"/>'
        '<ellipse cx="60" cy="47" rx="4" ry="2.5" fill="#333"/>'
        '<path d="M56 50 Q60 53 64 50" stroke="#333" stroke-width="1.5" fill="none"/>',
    )

    make_svg(
        "block",
        "#E8EAF6",
        "#283593",
        '<rect x="35" y="40" width="50" height="45" rx="4" fill="#5C6BC0" stroke="#3949AB" stroke-width="2"/>'
        '<text x="60" y="72" text-anchor="middle" font-size="28" fill="#fff" font-weight="bold">A</text>',
    )

    # ============================================================
    # SHAPES
    # ============================================================

    make_svg(
        "circle_shape",
        "#E8F5E9",
        "#2E7D32",
        '<circle cx="60" cy="60" r="25" fill="#66BB6A" stroke="#2E7D32" stroke-width="3"/>',
    )

    make_svg(
        "square_shape",
        "#E3F2FD",
        "#1565C0",
        '<rect x="35" y="35" width="50" height="50" rx="4" fill="#42A5F5" stroke="#1565C0" stroke-width="3"/>',
    )

    make_svg(
        "triangle_shape",
        "#FFF3E0",
        "#E65100",
        '<polygon points="60,30 90,85 30,85" fill="#FF9800" stroke="#E65100" stroke-width="3"/>',
    )

    make_svg(
        "heart",
        "#FCE4EC",
        "#C62828",
        '<path d="M60 85 Q20 55 40 35 Q50 25 60 40 Q70 25 80 35 Q100 55 60 85Z" fill="#E53935" stroke="#C62828" stroke-width="2"/>',
    )

    # ============================================================
    # MUSICAL INSTRUMENTS
    # ============================================================

    make_svg(
        "guitar",
        "#FFF8E1",
        "#E65100",
        '<ellipse cx="55" cy="72" rx="18" ry="15" fill="#FFCC80" stroke="#E65100" stroke-width="2"/>'
        '<circle cx="55" cy="72" r="5" fill="#5D4037"/>'
        '<rect x="53" y="30" width="5" height="42" rx="2" fill="#8D6E63"/>'
        '<rect x="48" y="28" width="15" height="8" rx="3" fill="#8D6E63"/>'
        '<line x1="50" y1="30" x2="50" y2="28" stroke="#333" stroke-width="1"/>'
        '<line x1="55" y1="30" x2="55" y2="28" stroke="#333" stroke-width="1"/>'
        '<line x1="60" y1="30" x2="60" y2="28" stroke="#333" stroke-width="1"/>',
    )

    make_svg(
        "drum",
        "#FFEBEE",
        "#B71C1C",
        '<ellipse cx="60" cy="45" rx="25" ry="8" fill="#EF9A9A" stroke="#E53935" stroke-width="2"/>'
        '<rect x="35" y="45" width="50" height="30" fill="#EF5350" stroke="#E53935" stroke-width="2"/>'
        '<ellipse cx="60" cy="75" rx="25" ry="8" fill="#EF9A9A" stroke="#E53935" stroke-width="2"/>'
        '<line x1="35" y1="50" x2="85" y2="70" stroke="#FDD835" stroke-width="1.5"/>'
        '<line x1="85" y1="50" x2="35" y2="70" stroke="#FDD835" stroke-width="1.5"/>',
    )

    make_svg(
        "piano",
        "#ECEFF1",
        "#37474F",
        '<rect x="30" y="40" width="60" height="40" rx="3" fill="#333"/>'
        '<rect x="33" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="42" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="51" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="60" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="69" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="78" y="43" width="7" height="34" rx="1" fill="#fff"/>'
        '<rect x="38" y="43" width="5" height="22" rx="1" fill="#333"/>'
        '<rect x="47" y="43" width="5" height="22" rx="1" fill="#333"/>'
        '<rect x="65" y="43" width="5" height="22" rx="1" fill="#333"/>'
        '<rect x="74" y="43" width="5" height="22" rx="1" fill="#333"/>',
    )

    # ============================================================
    # PEOPLE & SOCIAL
    # ============================================================

    make_svg(
        "mother",
        "#FCE4EC",
        "#AD1457",
        '<circle cx="60" cy="38" r="14" fill="#FFCCBC"/>'
        '<path d="M46 30 Q52 18 60 22 Q68 18 74 30" fill="#5D4037"/>'
        '<circle cx="55" cy="36" r="2" fill="#333"/><circle cx="65" cy="36" r="2" fill="#333"/>'
        '<path d="M57 42 Q60 44 63 42" stroke="#E91E63" stroke-width="1.5" fill="none"/>'
        '<path d="M48 55 L42 92 L78 92 L72 55Z" fill="#E91E63"/>'
        '<path d="M48 55 L38 70 M72 55 L82 70" stroke="#E91E63" stroke-width="4"/>',
    )

    make_svg(
        "father",
        "#E3F2FD",
        "#0D47A1",
        '<circle cx="60" cy="38" r="14" fill="#FFCCBC"/>'
        '<path d="M46 32 Q60 22 74 32" fill="#333"/>'
        '<circle cx="55" cy="36" r="2" fill="#333"/><circle cx="65" cy="36" r="2" fill="#333"/>'
        '<path d="M57 42 Q60 44 63 42" stroke="#795548" stroke-width="1.5" fill="none"/>'
        '<path d="M48 55 L42 92 L78 92 L72 55Z" fill="#1565C0"/>'
        '<path d="M48 55 L38 70 M72 55 L82 70" stroke="#1565C0" stroke-width="4"/>',
    )

    make_svg(
        "happy_face",
        "#FFF8E1",
        "#FF6F00",
        '<circle cx="60" cy="60" r="28" fill="#FDD835"/>'
        '<circle cx="48" cy="52" r="4" fill="#333"/><circle cx="72" cy="52" r="4" fill="#333"/>'
        '<path d="M42 68 Q60 85 78 68" stroke="#333" stroke-width="3" fill="none"/>',
    )

    make_svg(
        "sad_face",
        "#E3F2FD",
        "#0D47A1",
        '<circle cx="60" cy="60" r="28" fill="#90CAF9"/>'
        '<circle cx="48" cy="52" r="4" fill="#333"/><circle cx="72" cy="52" r="4" fill="#333"/>'
        '<path d="M42 78 Q60 65 78 78" stroke="#333" stroke-width="3" fill="none"/>',
    )

    make_svg(
        "waving",
        "#E8F5E9",
        "#2E7D32",
        '<circle cx="60" cy="40" r="12" fill="#FFCCBC"/>'
        '<circle cx="56" cy="38" r="2" fill="#333"/><circle cx="64" cy="38" r="2" fill="#333"/>'
        '<path d="M58 44 Q60 46 62 44" stroke="#E91E63" stroke-width="1.2" fill="none"/>'
        '<rect x="50" y="52" width="20" height="30" rx="4" fill="#4CAF50"/>'
        '<path d="M70 55 L85 35" stroke="#FFCCBC" stroke-width="5" stroke-linecap="round"/>'
        '<path d="M50 55 L40 70" stroke="#FFCCBC" stroke-width="5" stroke-linecap="round"/>',
    )

    make_svg(
        "thumbs_up",
        "#E8F5E9",
        "#2E7D32",
        '<rect x="40" y="50" width="30" height="30" rx="5" fill="#FFCCBC"/>'
        '<rect x="45" y="25" width="12" height="30" rx="5" fill="#FFCCBC"/>'
        '<rect x="40" y="58" width="30" height="4" rx="2" fill="#FFAB91"/>'
        '<rect x="40" y="66" width="30" height="4" rx="2" fill="#FFAB91"/>',
    )

    make_svg(
        "stop_hand",
        "#FFEBEE",
        "#C62828",
        '<circle cx="60" cy="62" r="26" fill="#FFCCBC"/>'
        '<rect x="44" y="30" width="5" height="28" rx="2.5" fill="#FFCCBC"/>'
        '<rect x="52" y="25" width="5" height="33" rx="2.5" fill="#FFCCBC"/>'
        '<rect x="60" y="25" width="5" height="33" rx="2.5" fill="#FFCCBC"/>'
        '<rect x="68" y="30" width="5" height="28" rx="2.5" fill="#FFCCBC"/>'
        '<rect x="37" y="55" width="5" height="18" rx="2.5" fill="#FFCCBC" transform="rotate(-30 40 65)"/>',
    )

    # ============================================================
    # ACTIONS / CONCEPTS
    # ============================================================

    make_svg(
        "sleeping",
        "#E8EAF6",
        "#283593",
        '<ellipse cx="60" cy="70" rx="25" ry="12" fill="#C5CAE9"/>'
        '<circle cx="60" cy="58" r="14" fill="#FFCCBC"/>'
        '<path d="M50 56 L55 56" stroke="#333" stroke-width="2"/>'
        '<path d="M65 56 L70 56" stroke="#333" stroke-width="2"/>'
        '<ellipse cx="60" cy="62" rx="3" ry="2" fill="#333"/>'
        '<text x="80" y="42" font-size="12" fill="#3F51B5" font-weight="bold">Z</text>'
        '<text x="86" y="34" font-size="10" fill="#3F51B5" font-weight="bold">z</text>'
        '<text x="90" y="28" font-size="8" fill="#3F51B5" font-weight="bold">z</text>',
    )

    make_svg(
        "eating",
        "#FFF8E1",
        "#F57F17",
        '<circle cx="60" cy="50" r="14" fill="#FFCCBC"/>'
        '<circle cx="55" cy="48" r="2" fill="#333"/><circle cx="65" cy="48" r="2" fill="#333"/>'
        '<ellipse cx="60" cy="56" rx="4" ry="3" fill="#333"/>'
        '<ellipse cx="60" cy="78" rx="20" ry="6" fill="#BDBDBD"/>'
        '<circle cx="55" cy="76" r="4" fill="#8BC34A"/><circle cx="65" cy="76" r="3" fill="#FF9800"/>',
    )

    make_svg(
        "more",
        "#E8F5E9",
        "#2E7D32",
        '<circle cx="60" cy="60" r="25" fill="#A5D6A7"/>'
        '<line x1="48" y1="60" x2="72" y2="60" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
        '<line x1="60" y1="48" x2="60" y2="72" stroke="#fff" stroke-width="5" stroke-linecap="round"/>',
    )

    make_svg(
        "water",
        "#E3F2FD",
        "#0D47A1",
        '<path d="M60 30 Q45 55 45 70 Q45 85 60 90 Q75 85 75 70 Q75 55 60 30Z" fill="#42A5F5" stroke="#1565C0" stroke-width="2"/>'
        '<path d="M53 65 Q58 60 63 65" fill="#fff" opacity="0.4"/>',
    )

    make_svg(
        "soap",
        "#F3E5F5",
        "#7B1FA2",
        '<rect x="38" y="50" width="44" height="30" rx="8" fill="#CE93D8" stroke="#7B1FA2" stroke-width="2"/>'
        '<circle cx="50" cy="42" r="5" fill="#E1BEE7" opacity="0.7"/>'
        '<circle cx="62" cy="38" r="7" fill="#E1BEE7" opacity="0.6"/>'
        '<circle cx="72" cy="44" r="4" fill="#E1BEE7" opacity="0.7"/>'
        '<circle cx="55" cy="35" r="3" fill="#E1BEE7" opacity="0.5"/>',
    )

    make_svg(
        "flashlight",
        "#FFF8E1",
        "#F57F17",
        '<rect x="50" y="50" width="20" height="40" rx="4" fill="#9E9E9E"/>'
        '<rect x="48" y="45" width="24" height="10" rx="3" fill="#757575"/>'
        '<path d="M48 45 L42 30 Q60 15 78 30 L72 45" fill="#FDD835"/>'
        '<circle cx="60" cy="28" r="6" fill="#fff" opacity="0.6"/>',
    )

    make_svg(
        "chopsticks",
        "#EFEBE9",
        "#4E342E",
        '<line x1="48" y1="30" x2="55" y2="90" stroke="#8D6E63" stroke-width="3" stroke-linecap="round"/>'
        '<line x1="72" y1="30" x2="65" y2="90" stroke="#8D6E63" stroke-width="3" stroke-linecap="round"/>',
    )

    make_svg(
        "crayon",
        "#FCE4EC",
        "#AD1457",
        '<rect x="45" y="30" width="30" height="50" rx="3" fill="#E91E63"/>'
        '<polygon points="45,80 60,95 75,80" fill="#AD1457"/>'
        '<rect x="45" y="30" width="30" height="10" rx="3" fill="#C2185B"/>'
        '<rect x="52" y="34" width="16" height="4" rx="2" fill="#F48FB1"/>',
    )

    # ============================================================
    # DIMENSION ICONS
    # ============================================================

    make_svg(
        "dim_object_cognition",
        "#E8F5E9",
        "#2E7D32",
        '<circle cx="45" cy="50" r="12" fill="#66BB6A" stroke="#2E7D32" stroke-width="2"/>'
        '<circle cx="75" cy="50" r="12" fill="#66BB6A" stroke="#2E7D32" stroke-width="2"/>'
        '<circle cx="60" cy="75" r="12" fill="#66BB6A" stroke="#2E7D32" stroke-width="2"/>'
        '<line x1="45" y1="50" x2="75" y2="50" stroke="#2E7D32" stroke-width="2" stroke-dasharray="4"/>'
        '<line x1="45" y1="50" x2="60" y2="75" stroke="#2E7D32" stroke-width="2" stroke-dasharray="4"/>'
        '<line x1="75" y1="50" x2="60" y2="75" stroke="#2E7D32" stroke-width="2" stroke-dasharray="4"/>',
    )

    make_svg(
        "dim_language_expression",
        "#E3F2FD",
        "#1565C0",
        '<path d="M35 45 Q35 35 60 35 Q85 35 85 45 L85 65 Q85 75 60 75 L50 75 L40 85 L42 75 Q35 75 35 65Z" fill="#42A5F5" stroke="#1565C0" stroke-width="2"/>'
        '<circle cx="48" cy="55" r="3" fill="#fff"/>'
        '<circle cx="60" cy="55" r="3" fill="#fff"/>'
        '<circle cx="72" cy="55" r="3" fill="#fff"/>',
    )

    make_svg(
        "dim_language_comprehension",
        "#FFF3E0",
        "#E65100",
        '<circle cx="60" cy="55" r="22" fill="#FFB74D" stroke="#E65100" stroke-width="2"/>'
        '<circle cx="52" cy="50" r="3" fill="#333"/><circle cx="68" cy="50" r="3" fill="#333"/>'
        '<path d="M50 62 Q60 70 70 62" stroke="#333" stroke-width="2" fill="none"/>'
        '<path d="M85 40 L90 30 L80 33" stroke="#E65100" stroke-width="2.5" fill="none"/>'
        '<path d="M35 40 L30 30 L40 33" stroke="#E65100" stroke-width="2.5" fill="none"/>',
    )

    make_svg(
        "dim_literacy",
        "#F3E5F5",
        "#7B1FA2",
        '<rect x="35" y="35" width="50" height="50" rx="3" fill="#CE93D8" stroke="#7B1FA2" stroke-width="2"/>'
        '<text x="60" y="58" text-anchor="middle" font-size="16" fill="#fff" font-weight="bold">ABC</text>'
        '<text x="60" y="76" text-anchor="middle" font-size="12" fill="#fff">abc</text>',
    )

    make_svg(
        "dim_social_behavior",
        "#FCE4EC",
        "#C62828",
        '<circle cx="42" cy="48" r="10" fill="#FFCCBC"/><circle cx="78" cy="48" r="10" fill="#FFCCBC"/>'
        '<circle cx="42" cy="46" r="1.5" fill="#333"/><circle cx="78" cy="46" r="1.5" fill="#333"/>'
        '<path d="M39 52 Q42 54 45 52" stroke="#333" stroke-width="1" fill="none"/>'
        '<path d="M75 52 Q78 54 81 52" stroke="#333" stroke-width="1" fill="none"/>'
        '<path d="M52 55 Q60 45 68 55" stroke="#E91E63" stroke-width="2" fill="none"/>'
        '<path d="M60 75 Q40 65 45 55" stroke="#E91E63" stroke-width="1.5" fill="none" stroke-dasharray="3"/>'
        '<path d="M60 75 Q80 65 75 55" stroke="#E91E63" stroke-width="1.5" fill="none" stroke-dasharray="3"/>',
    )

    make_svg(
        "dim_cognitive_logic",
        "#E8EAF6",
        "#283593",
        '<rect x="30" y="40" width="22" height="22" rx="3" fill="#5C6BC0"/>'
        '<circle cx="75" cy="51" r="12" fill="#7C4DFF"/>'
        '<polygon points="60,72 48,92 72,92" fill="#FF7043"/>'
        '<text x="41" y="56" text-anchor="middle" font-size="14" fill="#fff" font-weight="bold">?</text>',
    )

    # ============================================================
    # REWARDS / FEEDBACK
    # ============================================================

    make_svg(
        "reward_star",
        "#FFF8E1",
        "#FF6F00",
        '<polygon points="60,18 68,45 97,45 74,62 82,90 60,73 38,90 46,62 23,45 52,45" fill="#FDD835" stroke="#FF6F00" stroke-width="2"/>'
        '<circle cx="60" cy="55" r="8" fill="#FFE082"/>',
    )

    make_svg(
        "reward_trophy",
        "#FFF8E1",
        "#FF6F00",
        '<rect x="45" y="75" width="30" height="8" rx="3" fill="#FDD835"/>'
        '<rect x="52" y="65" width="16" height="12" rx="2" fill="#FBC02D"/>'
        '<path d="M42 35 L42 55 Q42 68 60 68 Q78 68 78 55 L78 35Z" fill="#FDD835" stroke="#FF6F00" stroke-width="2"/>'
        '<path d="M42 40 Q28 40 28 50 Q28 60 42 55" fill="#FBC02D"/>'
        '<path d="M78 40 Q92 40 92 50 Q92 60 78 55" fill="#FBC02D"/>'
        '<text x="60" y="56" text-anchor="middle" font-size="16" fill="#FF6F00" font-weight="bold">1</text>',
    )

    make_svg(
        "reward_ribbon",
        "#E8EAF6",
        "#283593",
        '<circle cx="60" cy="45" r="18" fill="#5C6BC0" stroke="#3949AB" stroke-width="2"/>'
        '<circle cx="60" cy="45" r="12" fill="#7986CB"/>'
        '<polygon points="48,60 42,90 52,78 60,90 68,78 78,90 72,60" fill="#5C6BC0"/>'
        '<text x="60" y="50" text-anchor="middle" font-size="14" fill="#fff" font-weight="bold">A+</text>',
    )

    make_svg(
        "reward_fireworks",
        "#1A237E",
        "#FFD740",
        '<circle cx="40" cy="40" r="3" fill="#FF5252"/>'
        '<circle cx="80" cy="35" r="3" fill="#FFEB3B"/>'
        '<circle cx="60" cy="50" r="3" fill="#69F0AE"/>'
        '<line x1="40" y1="40" x2="30" y2="30" stroke="#FF5252" stroke-width="1.5"/>'
        '<line x1="40" y1="40" x2="35" y2="50" stroke="#FF5252" stroke-width="1.5"/>'
        '<line x1="40" y1="40" x2="50" y2="35" stroke="#FF5252" stroke-width="1.5"/>'
        '<line x1="80" y1="35" x2="90" y2="25" stroke="#FFEB3B" stroke-width="1.5"/>'
        '<line x1="80" y1="35" x2="85" y2="45" stroke="#FFEB3B" stroke-width="1.5"/>'
        '<line x1="80" y1="35" x2="70" y2="30" stroke="#FFEB3B" stroke-width="1.5"/>'
        '<line x1="60" y1="50" x2="55" y2="40" stroke="#69F0AE" stroke-width="1.5"/>'
        '<line x1="60" y1="50" x2="65" y2="40" stroke="#69F0AE" stroke-width="1.5"/>'
        '<line x1="60" y1="50" x2="60" y2="60" stroke="#69F0AE" stroke-width="1.5"/>'
        '<circle cx="50" cy="70" r="2" fill="#FF80AB"/>'
        '<circle cx="70" cy="75" r="2" fill="#82B1FF"/>'
        '<circle cx="45" cy="60" r="1.5" fill="#B388FF"/>'
        '<circle cx="75" cy="55" r="1.5" fill="#FFD740"/>',
    )

    print(f"Generated {len(os.listdir(OUTPUT_DIR))} SVG icons in {OUTPUT_DIR}")


if __name__ == "__main__":
    generate_all()
