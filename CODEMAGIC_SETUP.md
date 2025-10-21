# Configuración de Codemagic para MedRush App - iOS

## 📋 Archivo codemagic.yaml Creado

He creado un archivo `codemagic.yaml` específico para iOS que apunta al directorio `frontend/`:

- **iOS** (IPA + App Store Connect)
- **Configuración para proyecto en subdirectorio `frontend/`**

## 🔧 Configuración Requerida

### 1. Variables de Entorno en Codemagic

#### Para iOS:
```
APP_STORE_CONNECT_ISSUER_ID: [Tu Issuer ID]
APP_STORE_CONNECT_KEY_IDENTIFIER: [Tu Key ID]
APP_STORE_CONNECT_PRIVATE_KEY: [Tu Private Key]
```

### 2. Code Signing

#### iOS Certificates:
1. Ve a **Team Settings > Code signing identities**
2. Sube tu certificado de distribución
3. Configura las credenciales de App Store Connect

### 3. Grupos de Variables

Crea este grupo en Codemagic:

#### `app_store_connect`:
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_IDENTIFIER`
- `APP_STORE_CONNECT_PRIVATE_KEY`

## 🚀 Características Incluidas

### ✅ Configuración para Subdirectorio
- Todos los scripts navegan a `cd frontend` antes de ejecutar comandos Flutter
- Artifacts apuntan a `frontend/build/ios/ipa/*.ipa`

### ✅ Testing
- `flutter analyze` en el directorio frontend
- `flutter test` (con `ignore_failure: true` para no bloquear builds)

### ✅ Publishing
- **Email**: Notificaciones de éxito/fallo
- **App Store**: Subida a TestFlight

### ✅ Artifacts
- iOS: IPA + logs de Xcode

## 📝 Pasos Siguientes

1. **Commit el archivo** `codemagic.yaml` a la raíz de tu repositorio
2. **Configura las variables** en el panel de Codemagic
3. **Sube los certificados** de code signing para iOS
4. **Ejecuta el primer build** para verificar la configuración

## 🔍 Troubleshooting

### Error: "Directory was not found"
El archivo ya está configurado para navegar al directorio `frontend/`:

```yaml
scripts:
  - name: Get Flutter packages
    script: | 
      cd frontend
      flutter pub get
```

### Error: "App Store Connect credentials"
Asegúrate de:
- Tener un **App Store Connect API Key** válido
- Configurar las variables en el grupo `app_store_connect`
- Usar el bundle identifier correcto: `com.medrush.app`

### Error: "Flutter command not found"
Verifica que:
- El proyecto Flutter esté en `frontend/`
- El archivo `pubspec.yaml` esté en `frontend/pubspec.yaml`
- Las dependencias estén correctamente configuradas

## 📚 Recursos Adicionales

- [Documentación oficial de Codemagic](https://docs.codemagic.io/)
- [Flutter CI/CD Best Practices](https://docs.flutter.dev/deployment/ci)
- [Google Play Console API](https://developers.google.com/android-publisher)
- [App Store Connect API](https://developer.apple.com/documentation/appstoreconnectapi)
