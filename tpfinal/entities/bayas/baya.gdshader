shader_type canvas_item;
render_mode unshaded;

uniform float tamano : hint_range(0.1, 3.0) = 1.0;
uniform float intensidad : hint_range(0.0, 1.0) = 0.7;

void fragment() {
    // Coordenadas centradas.
    vec2 centro = (UV - vec2(0.5)) * 2.0;

    // Controla el tamaño del brillo sin deformar el círculo.
    float distancia = length(centro) / tamano;

    // Caída exponencial: centro brillante y bordes muy difuminados.
    float halo = exp(-distancia * distancia * 5.0);

    // Pulso continuo de intensidad, como un corazón latiendo.
    float pulso = 0.75 + 0.25 * sin(TIME * 3.0);

    // Transparencia gradual para eliminar el cuadrado.
    float alfa = halo * intensidad * pulso;

    COLOR = vec4(1.0, 0.85, 0.2, alfa);
}