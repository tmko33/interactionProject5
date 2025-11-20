import oscP5.*;
import netP5.*;
import processing.data.*;

OscP5 oscP5;
int puerto;

ArrayList<Circulo> circulos = new ArrayList<Circulo>();

int numCarriles = 6;
float[] posicionesX;
float anchoCarril;
float zonaAltura = 80;

float diametro = 50;
int maxCirculos = 200;

boolean[] teclasPresionadas;

float[] frecuenciasIncorrectas = {
  180.0, 220.0, 260.0, 310.0, 360.0, 400.0
};

int[] escalaBase = {60, 62, 64, 65, 67, 69, 71}; 

float[] frecuenciasNiveles = {
  600.0, 700.0, 800.0, 900.0, 1000.0, 1200.0
};

int contadorAciertos = 0;
int nivel = 0;
int contadorEstrellas = 0;
color fondoActual = color(0);

void setup() {
  size(400, 400);
  background(0);

  puerto = 11111;
  oscP5 = new OscP5(this, puerto);

  anchoCarril = width / float(numCarriles);

  posicionesX = new float[numCarriles];
  for (int i = 0; i < numCarriles; i++) {
    posicionesX[i] = anchoCarril * 0.5 + i * anchoCarril;
  }

  teclasPresionadas = new boolean[numCarriles];

  cargarDatosDeArchivo("imdb_data.csv");
}

void draw() {
  background(fondoActual);
  noStroke();

  for (int i = 0; i < numCarriles; i++) {
    color rectColor = color(184, 134, 11);
    boolean hayFiguraEnZona = false;

    for (Circulo c : circulos) {
      if (millis() >= c.tiempoGeneracion && c.carril == i) {
        if (c.y + c.diametro / 2 >= height - zonaAltura &&
            c.y - c.diametro / 2 <= height) {
          hayFiguraEnZona = true;
          break;
        }
      }
    }

    if (teclasPresionadas[i]) {
      rectColor = hayFiguraEnZona ? color(173, 216, 230) : color(255, 0, 0);
    }

    float x0 = i * anchoCarril;
    drawRectangle(x0, height - zonaAltura, anchoCarril, zonaAltura, color(255));
    drawRectangle(x0 + 5, height - zonaAltura + 5, anchoCarril - 10, zonaAltura - 10, rectColor);
  }

  for (int i = circulos.size() - 1; i >= 0; i--) {
    Circulo c = circulos.get(i);

    if (millis() >= c.tiempoGeneracion) {
      c.update();
      c.display();

      int j = c.carril;
      boolean enZonaHit = c.y + c.diametro / 2 >= height - zonaAltura &&
                          c.y - c.diametro / 2 <= height;

      if (!c.mensajeImpreso && enZonaHit && teclasPresionadas[j]) {
        println("¡Frecuencia correcta: " + c.frecuencia + " Hz!  Título: " + c.titulo);
        c.mensajeImpreso = true;

        OscMessage mensajeOSC = new OscMessage("/notaCorrecta");
        mensajeOSC.add(c.frecuencia); 
        oscP5.send(mensajeOSC, new NetAddress("127.0.0.1", 11111));

        contadorAciertos++;

        if (contadorAciertos % 10 == 0) {
          contadorEstrellas++;
          if (contadorEstrellas > 10) contadorEstrellas = 10;
          nivel++;

          fondoActual = c.col;

          if (nivel >= frecuenciasNiveles.length) {
            nivel = frecuenciasNiveles.length - 1;
          }

          float freqNivel = frecuenciasNiveles[nivel];

          OscMessage nextLevelMsg = new OscMessage("/nextLevel");
          nextLevelMsg.add(freqNivel);  // Hz por nivel
          oscP5.send(nextLevelMsg, new NetAddress("127.0.0.1", 11111));
        }
      }
    }

    if (c.y - c.diametro / 2 > height) {
      circulos.remove(i);
    }
  }

  for (int i = 0; i < numCarriles; i++) {
    if (teclasPresionadas[i]) {
      boolean hayFiguraEnZona = false;

      for (Circulo c : circulos) {
        if (millis() >= c.tiempoGeneracion && c.carril == i) {
          if (c.y + c.diametro / 2 >= height - zonaAltura &&
              c.y - c.diametro / 2 <= height) {
            hayFiguraEnZona = true;
            break;
          }
        }
      }

      if (!hayFiguraEnZona) {
        println("No hay figuras en el carril " + (i + 1) + " en la zona de hit.");

        float freqError = frecuenciasIncorrectas[i];

        OscMessage mensajeOSC = new OscMessage("/notaIncorrecta");
        mensajeOSC.add(freqError); // Hz de error
        oscP5.send(mensajeOSC, new NetAddress("127.0.0.1", 11111));

        contadorAciertos = 0;
        nivel = 0;
        contadorEstrellas = 0;
        fondoActual = color(0);
      }
    }
  }

  fill(255);
  textSize(16);
  text("Aciertos: " + contadorAciertos, 10, 20);

  for (int i = 0; i < contadorEstrellas; i++) {
    fill(255, 215, 0);
    text("★", 10 + i * 15, 40);
  }
}

void cargarDatosDeArchivo(String rutaArchivo) {
  Table tabla = loadTable(rutaArchivo, "header");
  if (tabla == null) {
    println("No se pudo cargar el archivo CSV: " + rutaArchivo);
    return;
  }

  int count = 0;
  float duracionTotalMs = 120000.0;

  int[] ultimoTiempoCarril = new int[numCarriles];
  for (int i = 0; i < numCarriles; i++) {
    ultimoTiempoCarril[i] = -100000; 
  }
  int separacionMinimaCarril = 1500; 

  for (TableRow row : tabla.rows()) {
    if (count >= maxCirculos) {
      break;
    }

    String titleType = row.getString("titleType");
    String genres = row.getString("genres");
    String isAdultStr = row.getString("isAdult");
    String runtimeStr = row.getString("runtimeMinutes");
    String primaryTitle = row.getString("primaryTitle");

    if (runtimeStr == null || runtimeStr.equals("\\N")) {
      continue;
    }

    int runtime = int(runtimeStr);
    if (runtime <= 0) {
      continue;
    }

    color col = colorDesdeGeneros(genres);

    if (isAdultStr != null && isAdultStr.equals("1")) {
      col = color(red(col) * 0.5, green(col) * 0.5, blue(col) * 0.5);
    }

    float velocidad = map(runtime, 1, 200, 1.0, 3.5);
    if (velocidad < 1.0) velocidad = 1.0;
    if (velocidad > 4.0) velocidad = 4.0;

    int carril = runtime % numCarriles;

    // Tiempo de generación: escalonado + separación mínima por carril
    float baseT = map(count, 0, maxCirculos - 1, 0, duracionTotalMs);
    float jitter = random(-500, 500); // +-0.5 s
    int tiempoGeneracion = int(baseT + jitter);

    if (tiempoGeneracion < ultimoTiempoCarril[carril] + separacionMinimaCarril) {
      tiempoGeneracion = ultimoTiempoCarril[carril] + separacionMinimaCarril;
    }
    if (tiempoGeneracion < 0) tiempoGeneracion = 0;
    if (tiempoGeneracion > duracionTotalMs) tiempoGeneracion = int(duracionTotalMs);

    ultimoTiempoCarril[carril] = tiempoGeneracion;

    int notaMidi = notaDesdeGeneros(genres);
    float frecuencia = midiToFreq(notaMidi);

    int tipoFigura = int(random(4)); // 0,1,2,3 → círculo, cuadrado, triángulo, estrella

    float x = posicionesX[carril];
    float yInicial = -diametro;

    circulos.add(new Circulo(x, yInicial, diametro, col, velocidad,
                             tiempoGeneracion, frecuencia, carril, tipoFigura, primaryTitle));
    count++;
  }

  println("Se generaron " + count + " figuras desde el CSV.");
}

color colorDesdeGeneros(String genres) {
  if (genres == null) {
    return color(180);
  }

  genres = genres.toLowerCase();

  if (genres.indexOf("action") != -1) {
    return color(255, 0, 0);
  } else if (genres.indexOf("comedy") != -1) {
    return color(255, 255, 0);
  } else if (genres.indexOf("drama") != -1) {
    return color(128, 0, 128);
  } else if (genres.indexOf("horror") != -1) {
    return color(80, 0, 0);
  } else if (genres.indexOf("romance") != -1) {
    return color(255, 105, 180);
  } else if (genres.indexOf("sci-fi") != -1 || genres.indexOf("scifi") != -1 || genres.indexOf("sci fi") != -1) {
    return color(0, 255, 255);
  } else if (genres.indexOf("documentary") != -1) {
    return color(0, 200, 100);
  } else if (genres.indexOf("animation") != -1) {
    return color(255, 165, 0);
  } else {
    return color(180);
  }
}

int notaDesdeGeneros(String genres) {
  if (genres == null) {
    return escalaBase[int(random(escalaBase.length))];
  }

  String g = genres.toLowerCase();

  if (g.indexOf("action") != -1) {
    return 60; // C4
  } else if (g.indexOf("comedy") != -1) {
    return 64; // E4
  } else if (g.indexOf("drama") != -1) {
    return 67; // G4
  } else if (g.indexOf("horror") != -1) {
    return 48; // C3
  } else if (g.indexOf("romance") != -1) {
    return 72; // C5
  } else if (g.indexOf("sci-fi") != -1 || g.indexOf("scifi") != -1 || g.indexOf("sci fi") != -1) {
    return 80; // G#5
  } else if (g.indexOf("documentary") != -1) {
    return 55; // G3
  } else if (g.indexOf("animation") != -1) {
    return 76; // E5
  } else {
    return escalaBase[int(random(escalaBase.length))];
  }
}

void keyPressed() {
  if (key == '1') teclasPresionadas[0] = true;
  if (key == '2') teclasPresionadas[1] = true;
  if (key == '3') teclasPresionadas[2] = true;
  if (key == '4') teclasPresionadas[3] = true;
  if (key == '5') teclasPresionadas[4] = true;
  if (key == '6') teclasPresionadas[5] = true;
}

void keyReleased() {
  if (key == '1') teclasPresionadas[0] = false;
  if (key == '2') teclasPresionadas[1] = false;
  if (key == '3') teclasPresionadas[2] = false;
  if (key == '4') teclasPresionadas[3] = false;
  if (key == '5') teclasPresionadas[4] = false;
  if (key == '6') teclasPresionadas[5] = false;
}

float midiToFreq(int midi) {
  return 440.0 * pow(2.0, (midi - 69) / 12.0);
}

class Circulo {
  float x, y, diametro, velocidad;
  color col;
  int tiempoGeneracion;
  float frecuencia;
  int carril;
  int tipoFigura;
  String titulo;
  boolean mensajeImpreso = false;

  Circulo(float x, float y, float diametro, color col, float velocidad,
          int tiempoGeneracion, float frecuencia, int carril, int tipoFigura, String titulo) {
    this.x = x;
    this.y = y;
    this.diametro = diametro;
    this.col = col;
    this.velocidad = velocidad;
    this.tiempoGeneracion = tiempoGeneracion;
    this.frecuencia = frecuencia;
    this.carril = carril;
    this.tipoFigura = tipoFigura;
    this.titulo = titulo;
  }

  void update() {
    y += velocidad;
  }

  void display() {
    fill(col);

    switch (tipoFigura) {
      case 0:
        ellipse(x, y, diametro, diametro);
        break;

      case 1:
        rectMode(CENTER);
        rect(x, y, diametro, diametro);
        rectMode(CORNER);
        break;

      case 2:
        float h = diametro;
        triangle(
          x, y - h / 2,
          x - h / 2, y + h / 2,
          x + h / 2, y + h / 2
        );
        break;

      case 3: 
        drawStar(x, y, diametro * 0.25, diametro * 0.5, 5);
        break;
    }
  }
}

void drawRectangle(float x, float y, float w, float h, color c) {
  fill(c);
  rect(x, y, w, h);
}

void drawStar(float x, float y, float radius1, float radius2, int npoints) {
  float angle = TWO_PI / npoints;
  float halfAngle = angle / 2.0;
  beginShape();
  for (float a = 0; a < TWO_PI; a += angle) {
    float sx = x + cos(a) * radius2;
    float sy = y + sin(a) * radius2;
    vertex(sx, sy);
    sx = x + cos(a + halfAngle) * radius1;
    sy = y + sin(a + halfAngle) * radius1;
    vertex(sx, sy);
  }
  endShape(CLOSE);
}
