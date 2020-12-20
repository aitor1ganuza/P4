PAV - P4: reconocimiento y verificación del locutor
===================================================

Obtenga su copia del repositorio de la práctica accediendo a [Práctica 4](https://github.com/albino-pav/P4)
y pulsando sobre el botón `Fork` situado en la esquina superior derecha. A continuación, siga las
instrucciones de la [Práctica 2](https://github.com/albino-pav/P2) para crear una rama con el apellido de
los integrantes del grupo de prácticas, dar de alta al resto de integrantes como colaboradores del proyecto
y crear la copias locales del repositorio.

También debe descomprimir, en el directorio `PAV/P4`, el fichero [db_8mu.tgz](https://atenea.upc.edu/pluginfile.php/3145524/mod_assign/introattachment/0/spk_8mu.tgz?forcedownload=1)
con la base de datos oral que se utilizará en la parte experimental de la práctica.

Como entrega deberá realizar un *pull request* con el contenido de su copia del repositorio. Recuerde
que los ficheros entregados deberán estar en condiciones de ser ejecutados con sólo ejecutar:

~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~.sh
  make release
  run_spkid mfcc train test classerr verify verifyerr
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Recuerde que, además de los trabajos indicados en esta parte básica, también deberá realizar un proyecto
de ampliación, del cual deberá subir una memoria explicativa a Atenea y los ficheros correspondientes al
repositorio de la práctica.

A modo de memoria de la parte básica, complete, en este mismo documento y usando el formato *markdown*, los
ejercicios indicados.

## Ejercicios.

### SPTK, Sox y los scripts de extracción de características.

- Analice el script `wav2lp.sh` y explique la misión de los distintos comandos involucrados en el *pipeline*
  principal (`sox`, `$X2X`, `$FRAME`, `$WINDOW` y `$LPC`). Explique el significado de cada una de las 
  opciones empleadas y de sus valores.
 
 ```bash
 # Main command for feature extration
  sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpc_order > $base.lp
  ```
 
  `sox`: llamamos a este programa (ya utilizado en la práctica 1) para convertir la señal .WAV a formato raw para que x2x pueda leer el fichero (ya que x2x sólo puede leer formato raw)
  `$X2X`: es el programa de SPTK que permite la conversión entre distintos formatos de datos. En nuestro caso utilizamos +sf para pasar de short a float y así tener reales en coma flotante de 32 bits. El resultado le pasamos a la salida estándar. 
  `$FRAME`: divide la señal de entrada en tramas de 240 muestras (30 ms) con desplazamiento de ventana de
  80 muestras (10 ms) teniendo en cuenta que utilizamos frecuencia de muestreo de 8 kHz. 
  `$WINDOW`: multiplica cada trama por la ventana de Blackman (opción por defecto).
  `$LPC`: calcula los lpc_order primeros coeficientes de predicción lineal, precedidos por el factor de
  ganancia del predictor.

  El resultado del pipeline se redirecciona a un fichero temporal, ubicado en el directorio /tmp, y
  cuyo nombre es el mismo que el del script seguido del identificador del proceso (de este modo se
  consigue un fichero temporal único para cada ejecución).

- Explique el procedimiento seguido para obtener un fichero de formato *fmatrix* a partir de los ficheros de
  salida de SPTK (líneas 45 a 47 del script `wav2lp.sh`).

```bash
# Our array files need a header with the number of cols and rows:
ncol=$((lpc_order+1)) # lpc p =>  (gain a1 a2 ... ap) 
nrow=`$X2X +fa < $base.lp | wc -l | perl -ne 'print $_/'$ncol', "\n";'`
```
El fichero fmatrix se compone en número de filas y de columnas seguidos por los datos. 

El numero de columnas (ncol) será igual al número de coeficientes, con lo cual será fácil de calcularlo ya que es el orden del predictor + 1 ya que en el primer elemento del vector se almacena la ganancia de predicción. 

El número de filas será igual al número de tramas. Como depende de la longitud de la señal, el desplazamiento y longitud de la ventana y de la cadena de comandos que se ejecutan para obtener la parametrización; por todo ello, es mejor, simplemente, extraer esa información del fichero obtenido. Lo hacemos convirtiendo la señal parametrizada a texto, usando +fa, y contando el número de líneas, con el comando de UNIX wc -l.

  * ¿Por qué es conveniente usar este formato (u otro parecido)? Tenga en cuenta cuál es el formato de
    entrada y cuál es el de resultado.
    
    Porque de esta forma veremos a la salida el valor de los coeficientes en cada trama, siendo cada columna el valor de cada coeficiente y cada fila el número de trama, así queda una visualización en forma de matriz que es una manera bastante ordenada comparada con el fichero temporal generado.

- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales de predicción lineal
  (LPCC) en su fichero <code>scripts/wav2lpcc.sh</code>:

```bash
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$LPC -l 240 -m $lpc_order | $LPCC -m $lpc_order -M $lpcc_order > $base.lpcc
```

- Escriba el *pipeline* principal usado para calcular los coeficientes cepstrales en escala Mel (MFCC) en su
  fichero <code>scripts/wav2mfcc.sh</code>:

```bash
# Main command for feature extration
sox $inputfile -t raw -e signed -b 16 - | $X2X +sf | $FRAME -l 240 -p 80 | $WINDOW -l 240 -L 240 |
	$MFCC -s 8 -l 240 -m  $mfcc_order -n $filterbank_order > $base.mfcc
```

### Extracción de características.

- Inserte una imagen mostrando la dependencia entre los coeficientes 2 y 3 de las tres parametrizaciones
  para todas las señales de un locutor.
  
  <img src="Coef_2_3.png" width="960" align="center">


  + Indique **todas** las órdenes necesarias para obtener las gráficas a partir de las señales 
    parametrizadas.
  
    Primero hemos utilizado la ayuda aportada en el pdf de la práctica para obtener en un fichero de texto los coeficientes 2 y 3 de todos los ficheros de un locutor cualquiera (hemos utilizado el SES019 del BLOCK01):
    
    ```bash
    fmatrix_show work/lp/BLOCK01/SES019/*.lp | egrep '^\[' | cut -f4,5 > lp_2_3.txt
    fmatrix_show work/lpcc/BLOCK01/SES019/*.lpcc | egrep '^\[' | cut -f3,4 > lpcc_2_3.txt
    fmatrix_show work/mfcc/BLOCK01/SES019/*.mfcc | egrep '^\[' | cut -f3,4 > mfcc_2_3.txt
    ```

    Como es lógico tenemos que crear 3 ficheros de texto, uno para cada parametrización.

    Después hemos optado por hacer la gráfica con Matplotlib. El código para mostrar la gráfica anterior es el siguiente:

    ```py
    import matplotlib.pyplot as plt
    import matplotlib.cbook as cbook
    import numpy as np


    lp = np.loadtxt('lp_2_3.txt')
    lpcc = np.loadtxt('lpcc_2_3.txt')
    mfcc = np.loadtxt('mfcc_2_3.txt')

    fig, (axlp,axlpcc,axmfcc) = plt.subplots(3)
    fig.suptitle("Coeficientes 2 y 3 de las parametrizaciones LP, LPCC y MFCC de todas las señales de un locutor")
    axlp.plot(lp[:, 0], lp[:, 1],'.')
    axlpcc.plot(lpcc[:, 0], lpcc[:, 1],'.')
    axmfcc.plot(mfcc[:, 0], mfcc[:, 1],'.')
    axlp.set_title('LP')
    axlp.set(xlabel='Coeficientes 2', ylabel='Coeficientes 3')
    axlpcc.set_title('LPCC')
    axlpcc.set(xlabel='Coeficientes 2', ylabel='Coeficientes 3')
    axmfcc.set_title('MFCC')
    axmfcc.set(xlabel='Coeficientes 2', ylabel='Coeficientes 3')
    axlp.grid()
    axlpcc.grid()
    axmfcc.grid()
    plt.show()

    ```

  + ¿Cuál de ellas le parece que contiene más información?

  Contener más información en este contexto, es sinónimo de ver cuánto de correlados están los coeficientes entre sí. Si ambos toman valores muy parecidos (forman una recta o línea estrecha) carecen de información ya que a partir de uno de los coeficientes podemos saber el otro, en cambio, si toman valores muy distintos, la información que aportará ambos será el doble. Gráficamente podemos observar que:
  
  -LP: los coeficientes se concentran en una línea bastante estrecha sin casi espacios en blanco que tiende a ir estrechándose cada vez más, por lo que aportan poca información.

  -LPCC: aquí ya observamos una gran dispersión en los coeficientes donde ya no hay ninguna línea estrecha. Vemos que se empiezan a concentrar un poco más pasado el origen de los coeficientes de orden 2 pero por contra también se dispersan cada vez más en el eje de los coeficientes de orden 3 (se ensancha la posible recta), por lo que la información que aporta será elevada ya que se mantiene la dispersión.

  -MFCC: aquí la información se concentra un poco más que en el caso anterior, aunque se vea que los márgenes dinámicos són más elevados eso no implica que pueda aportar más información ya que sigue concentrada en casi todo ese márgen dinámico. Por otro lado, tampoco lo podemos interpretar como si fuera una recta estrecha ya que este margen dinámico hace que sea ancha y también se ven más espacios en blanco que en el caso de LP.

  Por lo tanto, en resumen, parece que la que más información puede obtener es la parametrización LPCC.
   

- Usando el programa <code>pearson</code>, obtenga los coeficientes de correlación normalizada entre los
  parámetros 2 y 3 para un locutor, y rellene la tabla siguiente con los valores obtenidos.

  |                        | LP   | LPCC | MFCC |
  |------------------------|:----:|:----:|:----:|
  | &rho;<sub>x</sub>[2,3] | -0.716101  |  -0.0375204    |  -0.349663    |
  
  + Compare los resultados de <code>pearson</code> con los obtenidos gráficamente.
  
  Los resultados son lo que esperábamos. El LP tal y como hemos razonado anteriormente aporta poca información entre sus coeficientes 2 y 3 (&rho;≈1;), el LPCC es el que más información aporta sin duda (&rho;≈0) y el MFCC podríamos pensar que tal y como hemos dicho como hay compensación pues &rho;≈0.5 pero como el margen dinámico es diferente eso hace que aún aporte un poco más de información. 
  
- Según la teoría, ¿qué parámetros considera adecuados para el cálculo de los coeficientes LPCC y MFCC?

Según la teoria, para reconocimiento del habla aproximadamente con 13 coeficentes LPCC o MFCC serian suficientes, y para el banco de filtros en el caso del MFCC, más o menos debemos seleccionar el doble de los coeficientes MFCC aunque en la práctica podemos seleccionar un poco menos del doble. 

### Entrenamiento y visualización de los GMM.

Complete el código necesario para entrenar modelos GMM.

- Inserte una gráfica que muestre la función de densidad de probabilidad modelada por el GMM de un locutor
  para sus dos primeros coeficientes de MFCC.
  
  Utilizamos la orden <code>plot_gmm_feat -x 2 -y 1 work/gmm/mfcc/SES000.gmm work/mfcc/BLOCK00/SES000/SA000S*<\code> y modificando el título, se obtiene la siguiente gráfica.
  
  <img src="plot_gmm_mfcc1.PNG" width="460" align="center">
  
- Inserte una gráfica que permita comparar los modelos y poblaciones de dos locutores distintos (la gŕafica
  de la página 20 del enunciado puede servirle de referencia del resultado deseado). Analice la capacidad
  del modelado GMM para diferenciar las señales de uno y otro.
  
  <img src="subplots.PNG" width="960" align="center">

### Reconocimiento del locutor.

Complete el código necesario para realizar reconociminto del locutor y optimice sus parámetros.

- Inserte una tabla con la tasa de error obtenida en el reconocimiento de los locutores de la base de datos
  SPEECON usando su mejor sistema de reconocimiento para los parámetros LP, LPCC y MFCC.

### Verificación del locutor.

Complete el código necesario para realizar verificación del locutor y optimice sus parámetros.

- Inserte una tabla con el *score* obtenido con su mejor sistema de verificación del locutor en la tarea
  de verificación de SPEECON. La tabla debe incluir el umbral óptimo, el número de falsas alarmas y de
  pérdidas, y el score obtenido usando la parametrización que mejor resultado le hubiera dado en la tarea
  de reconocimiento.
 
### Test final

- Adjunte, en el repositorio de la práctica, los ficheros `class_test.log` y `verif_test.log` 
  correspondientes a la evaluación *ciega* final.

### Trabajo de ampliación.

- Recuerde enviar a Atenea un fichero en formato zip o tgz con la memoria (en formato PDF) con el trabajo 
  realizado como ampliación, así como los ficheros `class_ampl.log` y/o `verif_ampl.log`, obtenidos como 
  resultado del mismo.
