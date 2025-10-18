<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Command;

class ListUsersCommand extends Command
{
  /**
   * The name and signature of the console command.
   *
   * @var string
   */
  protected $signature = 'app:list-users';

  /**
   * The console command description.
   *
   * @var string
   */
  protected $description = 'Lists all users with their primary role.';

  /**
   * Execute the console command.
   */
  public function handle()
  {
    $users = User::all(['id', 'name', 'email']);

    $headers = ['ID', 'Name', 'Email', 'Role'];
    $data = [];

    foreach ($users as $user) {
      $role = $user->getRoleNames()->first() ?? 'N/A';

      $data[] = [
        'id' => $user->id,
        'name' => $user->name,
        'email' => $user->email,
        'role' => $role,
      ];
    }

    $this->table($headers, $data);
  }
}
