# API de Autenticación - CinelarTV

## Base URL
```
https://your-domain.com/api/v1
```

## Resumen

API RESTful para clientes móviles/nativos (iOS, Android, etc.) que permite:
- Autenticación con email/username y password
- Obtención de tokens OAuth2 (access_token + refresh_token)
- Gestión de perfiles tipo Netflix
- Detección del perfil activo seleccionado

---

## Endpoints

### 1. Login

**POST** `/api/v1/auth/login`

Autentica al usuario y retorna tokens OAuth2 + datos del usuario.

#### Request Body
```json
{
  "email": "user@example.com",  // o "username": "miusuario"
  "password": "mi_password"
}
```

#### Response 200 - Éxito
```json
{
  "message": "Login successful",
  "access_token": "abc123...",
  "refresh_token": "def456...",
  "token_type": "Bearer",
  "expires_in": 7200,
  "created_at": 1712345678,
  "user": {
    "id": "uuid-123",
    "email": "user@example.com",
    "username": "miusuario",
    "admin": false,
    "profiles": [
      {
        "id": "profile-uuid-1",
        "name": "MIUSUARIO",
        "profile_type": "OWNER",
        "avatar_id": "coolCat"
      },
      {
        "id": "profile-uuid-2",
        "name": "Kids",
        "profile_type": "KIDS",
        "avatar_id": "happyDog"
      }
    ],
    "current_profile": {
      "id": "profile-uuid-1",
      "name": "MIUSUARIO",
      "profile_type": "OWNER",
      "avatar_id": "coolCat"
    }
  },
  "current_profile": {
    "id": "profile-uuid-1",
    "name": "MIUSUARIO",
    "profile_type": "OWNER",
    "avatar_id": "coolCat"
  }
}
```

#### Response 401 - Credenciales inválidas
```json
{
  "error": "invalid_credentials",
  "message": "The email/username or password you entered is incorrect"
}
```

---

### 2. Refresh Token

**POST** `/api/v1/auth/refresh`

Renueva un access_token usando el refresh_token.

#### Request Body
```json
{
  "refresh_token": "def456..."
}
```

#### Response 200 - Éxito
```json
{
  "access_token": "new_abc123...",
  "refresh_token": "new_def456...",
  "token_type": "Bearer",
  "expires_in": 7200,
  "created_at": 1712345999
}
```

#### Response 401 - Token inválido
```json
{
  "error": "invalid_refresh_token",
  "message": "Refresh token is invalid or expired"
}
```

---

### 3. Obtener Usuario Actual

**GET** `/api/v1/auth/me`

Obtiene el usuario autenticado con todos sus perfiles y el perfil actualmente seleccionado.

#### Headers
```
Authorization: Bearer <access_token>
```

#### Response 200 - Éxito
```json
{
  "user": {
    "id": "uuid-123",
    "email": "user@example.com",
    "username": "miusuario",
    "admin": false,
    "profiles": [...],
    "current_profile": {
      "id": "profile-uuid-1",
      "name": "MIUSUARIO",
      "profile_type": "OWNER",
      "avatar_id": "coolCat"
    }
  },
  "current_profile": {
    "id": "profile-uuid-1",
    "name": "MIUSUARIO",
    "profile_type": "OWNER",
    "avatar_id": "coolCat"
  },
  "needs_profile_selection": false
}
```

#### Response 401 - No autenticado
```json
{
  "error": "unauthorized",
  "message": "Invalid or expired token"
}
```

---

### 4. Estado del Perfil

**GET** `/api/v1/auth/profile-status`

Verifica si el usuario tiene un perfil seleccionado. Útil para determinar si mostrar la pantalla de selección de perfiles.

#### Headers
```
Authorization: Bearer <access_token>
```

#### Response 200 - Éxito
```json
{
  "authenticated": true,
  "has_profile_selected": true,
  "current_profile": {
    "id": "profile-uuid-1",
    "name": "MIUSUARIO",
    "profile_type": "OWNER",
    "avatar_id": "coolCat"
  },
  "profiles": [
    {
      "id": "profile-uuid-1",
      "name": "MIUSUARIO",
      "profile_type": "OWNER",
      "avatar_id": "coolCat"
    },
    {
      "id": "profile-uuid-2",
      "name": "Kids",
      "profile_type": "KIDS",
      "avatar_id": "happyDog"
    }
  ],
  "profiles_count": 2,
  "needs_profile_selection": false
}
```

---

### 5. Seleccionar Perfil

**POST** `/api/v1/auth/select-profile`

Selecciona un perfil activo para el usuario.

#### Headers
```
Authorization: Bearer <access_token>
```

#### Request Body
```json
{
  "profile_id": "profile-uuid-1"
}
```

#### Response 200 - Éxito
```json
{
  "message": "Profile selected successfully",
  "current_profile": {
    "id": "profile-uuid-1",
    "name": "MIUSUARIO",
    "profile_type": "OWNER",
    "avatar_id": "coolCat"
  },
  "user": {
    "id": "uuid-123",
    "email": "user@example.com",
    "username": "miusuario",
    "admin": false,
    "profiles": [...],
    "current_profile": {
      "id": "profile-uuid-1",
      "name": "MIUSUARIO",
      "profile_type": "OWNER",
      "avatar_id": "coolCat"
    }
  }
}
```

#### Response 422 - Profile ID faltante
```json
{
  "error": "missing_profile_id",
  "message": "Profile ID is required"
}
```

#### Response 404 - Perfil no encontrado
```json
{
  "error": "profile_not_found",
  "message": "Profile not found or doesn't belong to you"
}
```

---

### 6. Deseleccionar Perfil

**POST** `/api/v1/auth/deassign-profile`

Deselecciona el perfil activo actual.

#### Headers
```
Authorization: Bearer <access_token>
```

#### Response 200 - Éxito
```json
{
  "message": "Profile deselected successfully",
  "current_profile": null,
  "needs_profile_selection": true
}
```

---

### 7. Logout

**DELETE** `/api/v1/auth/logout`

Revoca el token actual y cierra la sesión.

#### Headers
```
Authorization: Bearer <access_token>
```

#### Response 200 - Éxito
```json
{
  "message": "Logout successful"
}
```

---

## Flujo Típico en App Móvil

### 1. Login Inicial
```
POST /api/v1/auth/login
→ Guardar access_token y refresh_token en secure storage
→ Verificar si current_profile existe
→ Si no existe, mostrar pantalla de selección de perfiles
```

### 2. Al Abrir la App
```
GET /api/v1/auth/profile-status (con access_token)
→ Si needs_profile_selection = true, mostrar selector de perfiles
→ Si has_profile_selected = true, ir al home con el perfil activo
```

### 3. Al Expirar el Token
```
POST /api/v1/auth/refresh
→ Actualizar access_token y refresh_token en secure storage
```

### 4. Seleccionar Perfil
```
POST /api/v1/auth/select-profile
→ Actualizar UI con el perfil seleccionado
```

### 5. Cambiar de Perfil
```
POST /api/v1/auth/select-profile (con otro profile_id)
→ Actualizar UI
```

### 6. Logout
```
DELETE /api/v1/auth/logout
→ Limpiar secure storage
→ Ir a pantalla de login
```

---

## Ejemplos de Código

### cURL - Login
```bash
curl -X POST https://your-domain.com/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "mysecret"
  }'
```

### cURL - Obtener Usuario
```bash
curl -X GET https://your-domain.com/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### cURL - Seleccionar Perfil
```bash
curl -X POST https://your-domain.com/api/v1/auth/select-profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "profile_id": "profile-uuid-123"
  }'
```

### JavaScript/Fetch - Login
```javascript
const login = async (email, password) => {
  const response = await fetch('/api/v1/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password })
  });
  
  if (response.ok) {
    const data = await response.json();
    // Guardar tokens
    localStorage.setItem('access_token', data.access_token);
    localStorage.setItem('refresh_token', data.refresh_token);
    return data;
  }
  
  throw new Error('Login failed');
};
```

### JavaScript/Fetch - Obtener Usuario
```javascript
const fetchCurrentUser = async () => {
  const token = localStorage.getItem('access_token');
  const response = await fetch('/api/v1/auth/me', {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  
  if (response.ok) {
    return await response.json();
  }
  
  throw new Error('Failed to fetch user');
};
```

### Swift (iOS) - Login
```swift
func login(email: String, password: String) async throws -> AuthResponse {
    let request = URLRequest(url: URL(string: "\(baseURL)/api/v1/auth/login")!)
        .setting(\.httpMethod, to: "POST")
        .setting(\.httpBody, to: try JSONEncoder().encode(LoginRequest(email: email, password: password)))
    
    let (data, _) = try await URLSession.shared.data(for: request)
    return try JSONDecoder().decode(AuthResponse.self, from: data)
}
```

### Kotlin (Android) - Login
```kotlin
data class LoginRequest(val email: String, val password: String)
data class AuthResponse(
    val access_token: String,
    val refresh_token: String,
    val user: User,
    val current_profile: Profile?
)

suspend fun login(email: String, password: String): AuthResponse {
    return retrofitService.login(LoginRequest(email, password))
}
```

---

## Notas de Seguridad

1. **Almacenar tokens de forma segura**:
   - iOS: Keychain
   - Android: EncryptedSharedPreferences / Keystore
   - Web: HttpOnly cookies (si es posible)

2. **No almacenar en**:
   - localStorage (web)
   - SharedPreferences sin encriptar
   - Archivos de texto plano

3. **Refresh automático**:
   - Implementar interceptor que detecte 401 y haga refresh
   - Si refresh falla, forzar login

4. **HTTPS siempre**:
   - No enviar tokens por HTTP plano
   - Usar certificate pinning en producción

---

## Endpoints Legacy (Web)

Estos endpoints siguen disponibles para la aplicación web:

- `GET /session/current` - Usuario actual (web session)
- `POST /session/select-profile` - Seleccionar perfil (web session)
- `POST /session/deassign-profile` - Deseleccionar perfil (web session)
- `GET /user/profiles` - Listar perfiles
- `GET /session/csrf` - Refresh CSRF token

Los nuevos clientes móviles deben usar los endpoints `/api/v1/auth/*`.
