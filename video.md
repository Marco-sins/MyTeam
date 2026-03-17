# Guion del Video TFG – Actividad 2: De la Idea a la Implementación

Duración orientativa: 5–10 minutos

---

## 1. Introducción

- Presentación:
  > Hola, soy [TU NOMBRE] y en este vídeo voy a explicar cómo hemos pasado de la idea inicial a la implementación real del proyecto, centrándome en la planificación técnica, los recursos, el marco legal y de seguridad, y la guía de despliegue.

- Contextualización del proyecto:
  > Se trata de una aplicación desarrollada con Flutter que [breve descripción funcional: por ejemplo, ayuda a X usuarios a hacer Y].

- Preguntas clave a responder:
  > A lo largo del vídeo responderé a cinco preguntas clave: en qué orden lo construimos, quién hace qué y con qué herramientas, si tenemos todos los permisos necesarios, qué pasa si algo falla en producción y, por último, cómo se instala y se despliega el sistema.

---

## 2. Secuenciación y Procedimientos

**Pregunta 1: ¿En qué orden vamos a construirlo?**

- Enfoque general:
  > Primero definí una secuenciación de tareas técnicas divididas en bloques de menos de 8 horas para poder planificar el trabajo de forma realista y medible.

- Fases del proyecto:
  1. **Preparación del entorno y repositorio:** Configuración de Flutter, creación del repositorio Git, definición de ramas (main/desarrollo/feature) y configuración básica.
  2. **Diseño de la arquitectura:** Definición de capas (data, domain, presentation), modelos de datos y estructura de directorios.
  3. **Implementación de casos de uso principales:** Desarrollo de pantallas clave, navegación y lógica de negocio principal.
  4. **Integración con APIs y servicios externos:** Conexión con backend, manejo de errores y validaciones.
  5. **Testing y corrección de errores:** Pruebas unitarias y manuales en distintos dispositivos.
  6. **Preparación del despliegue:** Configuración de firmas, builds de release y subida a las tiendas.

- Protocolo de trabajo:
  > Se sigue un protocolo claro de Git: cada tarea se realiza en una rama de feature, se abre un merge request/pull request, se revisa el código y luego se integra en la rama de desarrollo y posteriormente en la rama de producción.

---

## 3. Logística y Asignación de Recursos

**Pregunta 2: ¿Quién hace qué y con qué herramientas?**

- Matriz de responsabilidades:
  > Para asignar recursos y tiempos, he preparado una matriz donde se indica qué perfil sería responsable de cada tipo de tarea si el proyecto fuera real.

- Roles principales:
  - Análisis y diseño de arquitectura: Analista o desarrollador senior.
  - Desarrollo de pantallas y lógica: Desarrollador junior o en prácticas supervisado.
  - Despliegue y automatización: DevOps o desarrollador con experiencia en CI/CD.

- Logística de materiales y herramientas:
  > Para testing se requieren varios dispositivos Android, un emulador configurado y servicios como Firebase Test Lab. Se utilizan herramientas como GitHub/GitLab, gestor de incidencias y entornos separados de desarrollo y producción.

- Planificación realista:
  > Así se asignan responsables, tiempos, materiales y herramientas por tarea, cumpliendo con una planificación realista de recursos.

---

## 4. Marco Legal y de Seguridad

**Preguntas 3 y 4: ¿Tenemos permiso? ¿Qué hacemos si algo explota?**

### 4.1 Permisos y autorizaciones

- Permisos de publicación:
  > Es necesario disponer de cuentas de Google Play Console y Apple Developer, y aceptar licencias y condiciones de uso.

- Cumplimiento legal (RGPD y privacidad):
  > Se cumple el RGPD: solo se recogen datos mínimos, se informa al usuario mediante política de privacidad y se definen derechos de acceso, rectificación y eliminación.

- APIs de terceros:
  > Se revisan términos de uso, límites de cuotas y permisos de reutilización de datos de APIs externas.

### 4.2 Plan de prevención de riesgos

- Caída del servidor:
  > Se mantiene una versión estable anterior para rollback rápido, copias de seguridad y monitorización para restaurar el servicio.

- Fuga de datos:
  > Protocolo: aislar el sistema, revocar accesos, analizar datos comprometidos, notificar autoridades y usuarios, y aplicar medidas correctivas.

- Plan de contingencia:
  > Se dispone de un plan técnico centrado en backups, fallbacks y respuesta ante incidentes.

---

## 5. Documentación de Implementación

**Pregunta 5: ¿Cómo se instala?**

- Propósito de la guía:
  > Guía de instalación y despliegue para que cualquier programador pueda montar el entorno y subir la app a producción desde cero.

- Pasos principales de instalación:
  - Requisitos previos: Instalar Flutter, Git y Android Studio.
  - Clonado del repositorio.
  - Instalación de dependencias con `flutter pub get`.
  - Ejecución en modo desarrollo con `flutter run`.

- Pasos de despliegue:
  - Configuración de firma para Android.
  - Generación del artefacto de producción con `flutter build appbundle --release`.
  - Subida a Google Play Console y publicación de nueva versión.

- Guía profesional:
  > Explica cómo instalar, configurar y ejecutar el sistema paso a paso.

---

## 6. Cierre y Resumen Final

- Recapitulación:
  > En resumen, hemos visto en qué orden se construye el proyecto, quién se encarga de cada tarea y con qué recursos, qué permisos legales y de licencias son necesarios, cómo respondemos ante fallos o incidentes en producción y, finalmente, cómo se instala y se despliega técnicamente la aplicación.

- Objetivo general:
  > Todo este trabajo de documentación y planificación convierte la idea inicial en un proyecto realmente ejecutable y mantenible en un entorno profesional.

- Despedida:
  > Gracias por ver el vídeo.
