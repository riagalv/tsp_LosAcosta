const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

const db = admin.firestore();

// Función para calcular distancia entre dos puntos (fórmula Haversine)
function calcularDistancia(lat1, lon1, lat2, lon2) {
  const R = 6371; // Radio de la Tierra en km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = 
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) * 
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // Distancia en km
}

// Cloud Function que se ejecuta cuando se crea una nueva alerta
exports.enviarNotificacionAlertaCercana = functions.firestore
    .document('alertas/{alertaId}')
    .onCreate(async (snap, context) => {
      
      const alerta = snap.data();
      const { latitud, longitud, riesgo, direccion, emisor } = alerta;
      
      console.log(`🆕 Nueva alerta en: ${latitud}, ${longitud}`);
      
      // Radio en kilómetros (500m = 0.5km)
      const RADIO_KM = 0.5;
      
      try {
        // 1. Obtener todos los usuarios con token FCM
        const usuariosSnapshot = await db.collection('usuarios')
            .where('tokenFCM', '!=', null)
            .get();
        
        if (usuariosSnapshot.empty) {
          console.log('❌ No hay usuarios con token FCM');
          return null;
        }
        
        const tokensCercanos = [];
        
        // 2. Filtrar usuarios dentro del radio
        for (const doc of usuariosSnapshot.docs) {
          const usuario = doc.data();
          
          // Verificar que tenga ubicación reciente
          if (!usuario.ubicacion || !usuario.ultimaUbicacion) continue;
          
          const ultimaUbicacion = usuario.ultimaUbicacion.toDate();
          const horasDesdeActualizacion = (Date.now() - ultimaUbicacion) / (1000 * 60 * 60);
          
          if (horasDesdeActualizacion > 24) continue; // Ignorar ubicaciones muy antiguas
          
          const ubicacionUsuario = usuario.ubicacion;
          
          // Calcular distancia
          const distancia = calcularDistancia(
            latitud,
            longitud,
            ubicacionUsuario.latitud,
            ubicacionUsuario.longitud
          );
          
          // Si está dentro del radio, agregar token
          if (distancia <= RADIO_KM) {
            tokensCercanos.push(usuario.tokenFCM);
          }
        }
        
        console.log(`Usuarios cercanos encontrados: ${tokensCercanos.length}`);
        
        // 3. Enviar notificación a los tokens cercanos
        if (tokensCercanos.length > 0) {
          const mensaje = {
            notification: {
              title: '¡ALERTA CERCANA!',
              body: `${riesgo}: Perro agresivo reportado cerca de ${direccion}`,
            },
            data: {
              latitud: latitud.toString(),
              longitud: longitud.toString(),
              riesgo: riesgo,
              direccion: direccion,
              emisor: emisor || 'Anónimo',
              click_action: 'FLUTTER_NOTIFICATION_CLICK',
            },
            tokens: tokensCercanos,
          };
          
          const response = await admin.messaging().sendEachForMulticast(mensaje);
          console.log(`Notificaciones enviadas: ${response.successCount}`);
          console.log(`Fallidas: ${response.failureCount}`);
          
          // Actualizar contador de personas notificadas
          await snap.ref.update({
            'personasNotificadas': tokensCercanos.length,
          });
        } else {
          console.log('No hay usuarios cercanos para notificar');
        }
        
        return null;
        
      } catch (error) {
        console.error('Error enviando notificaciones:', error);
        return null;
      }
    });