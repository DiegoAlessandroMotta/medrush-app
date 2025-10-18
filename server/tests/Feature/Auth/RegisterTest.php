<?php

namespace Tests\Feature\Auth;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Foundation\Testing\WithFaker;
use Tests\TestCase;
use App\Models\User;
use Spatie\Permission\Models\Role;
use App\Enums\RolesEnum;
use PHPUnit\Framework\Attributes\Test;

class RegisterTest extends TestCase
{
  use RefreshDatabase;
  use WithFaker;

  protected function setUp(): void
  {
    parent::setUp();

    Role::create(['name' => RolesEnum::REPARTIDOR->value]);
    Role::create(['name' => RolesEnum::ADMINISTRADOR->value]);
  }

  #[Test]
  public function a_user_can_register_with_valid_credentials(): void
  {
    $userData = [
      'name' => 'Test User',
      'email' => $this->faker->unique()->safeEmail,
      'password' => 'password123',
      'password_confirmation' => 'password123',
      'device_name' => 'test_device',
    ];

    $response = $this->postJson('/api/auth/register', $userData);

    $response->assertStatus(201)
      ->assertJsonStructure([
        'status',
        'message',
        'data' => [
          'user' => [
            'id',
            'name',
            'email',
            'created_at',
            'updated_at',
          ],
          'access_token',
        ],
      ])
      ->assertJson([
        'status' => 'success',
        'message' => 'Usuario registrado exitosamente.',
        'data' => [
          'user' => [
            'name' => $userData['name'],
            'email' => $userData['email'],
          ],
        ],
      ]);

    // Asegúrate de que el usuario fue creado en la base de datos
    $this->assertDatabaseHas('users', [
      'email' => $userData['email'],
      'name' => $userData['name'],
    ]);

    // Opcional: Verifica que el usuario tenga el rol correcto (si usas Spatie Permission)
    $user = User::where('email', $userData['email'])->first();
    $this->assertTrue($user->hasRole(RolesEnum::REPARTIDOR->value));
  }

  #[Test]
  public function registration_fails_if_email_is_already_taken(): void
  {
    // Crea un usuario existente para simular el email duplicado
    User::factory()->create([
      'email' => 'existing@example.com',
    ]);

    $userData = [
      'name' => 'Another User',
      'email' => 'existing@example.com', // Este email ya existe
      'password' => 'password123',
      'password_confirmation' => 'password123',
      'device_name' => 'another_device',
    ];

    $response = $this->postJson('/api/auth/register', $userData);

    $response->assertStatus(422)
      ->assertJson([
        'status' => 'fail',
        'message' => 'Los datos proporcionados no son válidos.',
        'error' => [
          'code' => 'VALIDATION_ERROR',
          'errors' => [
            'email' => [
              'The email has already been taken.',
            ],
          ],
        ],
      ]);

    // Asegúrate de que no se creó un nuevo usuario con el email duplicado
    $this->assertDatabaseCount('users', 1);
  }

  #[Test]
  public function registration_fails_with_missing_required_fields(): void
  {
    // Test con datos incompletos (todos los campos requeridos faltan)
    $response = $this->postJson('/api/auth/register', []);

    $response->assertStatus(422)
      ->assertJson([
        'status' => 'fail',
        'message' => 'Los datos proporcionados no son válidos.',
        'error' => [
          'code' => 'VALIDATION_ERROR',
        ],
      ])
      ->assertJsonValidationErrors(['name', 'email', 'password', 'device_name'], 'error.errors');

    $this->assertDatabaseCount('users', 0);
  }

  #[Test]
  public function registration_fails_if_passwords_do_not_match(): void
  {
    $userData = [
      'name' => 'Test User',
      'email' => $this->faker->unique()->safeEmail,
      'password' => 'password123',
      'password_confirmation' => 'mismatch_password', // Contraseña diferente
      'device_name' => 'test_device',
    ];

    $response = $this->postJson('/api/auth/register', $userData);

    $response->assertStatus(422)
      ->assertJsonValidationErrors(['password'], 'error.errors');

    $this->assertDatabaseCount('users', 0);
  }

  #[Test]
  public function registration_fails_with_invalid_email_format(): void
  {
    $userData = [
      'name' => 'Test User',
      'email' => 'invalid-email', // Formato de email inválido
      'password' => 'password123',
      'password_confirmation' => 'password123',
      'device_name' => 'test_device',
    ];

    $response = $this->postJson('/api/auth/register', $userData);

    $response->assertStatus(422)
      ->assertJsonValidationErrors(['email'], 'error.errors');

    $this->assertDatabaseCount('users', 0);
  }

  #[Test]
  public function registration_fails_if_device_name_is_missing(): void
  {
    $userData = [
      'name' => 'Test User',
      'email' => $this->faker->unique()->safeEmail,
      'password' => 'password123',
      'password_confirmation' => 'password123',
      // 'device_name' está intencionalmente ausente
    ];

    $response = $this->postJson('/api/auth/register', $userData);

    $response->assertStatus(422)
      ->assertJsonValidationErrors(['device_name'], 'error.errors');

    $this->assertDatabaseCount('users', 0);
  }
}
