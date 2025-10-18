<?php

namespace App\Enums;

enum ResponseStatusEnum: string
{
  case SUCCESS = 'success';
  case FAIL = 'fail';
  case ERROR = 'error';
}
