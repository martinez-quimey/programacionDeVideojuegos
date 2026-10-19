
shader_type canvas_item;
render_mode unshaded;

uniform vec4 color_brillo : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float intensidad : hint_range(0.0, 1.0) = 0.35;
uniform float radio : hint_range(0.0, 0.5) = 0.18;
uniform float difusion : hint_range(0.01, 0.5) = 0.30;
uniform float velocidad : hint_range(0.0, 5.0) = 1.2;

void fragment() {
    vec2 centro = UV - vec2(0.5);
    float distancia = length(centro);

    float halo = 1.0 - smoothstep(
        radio,
        radio + difusion,
        distancia
    );

    float pulso = 0.85 + 0.15 * sin(TIME * velocidad);
    float alfa = halo * intensidad * pulso;

    COLOR = vec4(color_brillo.rgb, alfa);
}
