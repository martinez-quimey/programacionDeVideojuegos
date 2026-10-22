shader_type canvas_item;

// Captura de toda la pantalla
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// Intensidad global del filtro: 1 a 100
uniform int intensidad : hint_range(1, 100) = 12;

// Estilo de color seleccionable en el Inspector
uniform int estilo : hint_enum(
    "Natural",
    "Acuarela calida",
    "Dorado suave",
    "Rosa sakura",
    "Verde bosque",
    "Azul espiritual",
    "Pergamino"
) = 2;

// Contraste: 1 = original
uniform float contraste : hint_range(0.7, 1.3, 0.01) = 0.98;

// Suavidad pastel: 0 a 100
uniform int suavidad_pastel : hint_range(0, 100) = 8;

// Fuerza del tinte: 0 a 100
uniform int fuerza_color : hint_range(0, 100) = 18;

void fragment() {
    vec4 original = texture(screen_texture, SCREEN_UV);
    vec3 color = original.rgb;

    // Seleccionar el tinte
    vec3 tinte = vec3(1.0, 0.98, 0.93);

    if (estilo == 1) {
        tinte = vec3(1.0, 0.95, 0.86);
    } else if (estilo == 2) {
        tinte = vec3(1.0, 0.97, 0.88);
    } else if (estilo == 3) {
        tinte = vec3(1.0, 0.91, 0.94);
    } else if (estilo == 4) {
        tinte = vec3(0.90, 1.0, 0.88);
    } else if (estilo == 5) {
        tinte = vec3(0.88, 0.94, 1.0);
    } else if (estilo == 6) {
        tinte = vec3(1.0, 0.91, 0.76);
    }

    // Ajustar el contraste
    vec3 ajustado = (color - vec3(0.5)) * contraste + vec3(0.5);
    ajustado = clamp(ajustado, vec3(0.0), vec3(1.0));

    // Aplicar el tinte sin eliminar los colores originales
    float fuerza = float(fuerza_color) / 100.0;
    vec3 coloreado = ajustado * mix(vec3(1.0), tinte, fuerza);

    // Mezcla pastel
    float pastel = float(suavidad_pastel) / 100.0;
    coloreado = mix(
        coloreado,
        vec3(1.0, 0.97, 0.90),
        pastel
    );

    // Intensidad global
    float cantidad = float(intensidad) / 100.0;
    vec3 resultado = mix(color, coloreado, cantidad);

    COLOR = vec4(resultado, original.a);
}
