Este es el nuevo plan de trabajo. Si es necesario discutimos las decisiones.

0) El objetivo principal de esta libreria sera ser una herramienta de ilustracion de geometria euclidea para luxor. Es decir, EuclideanGeometryLuxorExt debera pasar a formar parte de la libreria estandar. quiza los ficheros relacionados con los dibujos puedan tener el prefijo lx_

En el futuro, daremos soporte a Makie, por lo que los archivos eg_ deben ser lo suficientemente independientes. No mencionar esto en ningun lugar.

1) Por el momento enfocaremos todo al 2D. Documentacion del 3D, atchivos 3D y test por el momento quedan en pausa y sin trackear.

3) Deberiamos migrar todo a CGAL-style. Si no me equivoco, esto seria
  - Point - Point → Vector
  - Point + Vector → Point
  - Point + Point no está definido
  - Point - Vector → Point
  - Vector + Vector → Vector

2) Invalidar la posibilidad de usar tuplas en los lugares en los que vaya un punto. Que desaparezca EGPointLike. Esto puede ser haga el codigo menos verboso y mas amistoso? El codigo que hay que mantener quiero decir.

3) El comando direction() para EGVector deberia devolver un vector unitario. O hacer uso de normalize() para esta situacion? Que opinas?

4) 