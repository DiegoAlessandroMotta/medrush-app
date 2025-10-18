<?php

namespace App\Enums;

enum PermissionsEnum: string
{
  case PEDIDOS_CREATE_ANY = 'pedidos:create.any';
  case PEDIDOS_CREATE_RELATED = 'pedidos:create.related';
  case PEDIDOS_VIEW_ANY = 'pedidos:view.any';
  case PEDIDOS_VIEW_RELATED = 'pedidos:view.related';
  case PEDIDOS_UPDATE_ANY = 'pedidos:update.any';
  case PEDIDOS_UPDATE_RELATED = 'pedidos:update.related';
  case PEDIDOS_DELETE_ANY = 'pedidos:delete.any';
  case PEDIDOS_DELETE_RELATED = 'pedidos:delete.related';

  case FARMACIAS_CREATE_ANY = 'farmacias:create.any';
  case FARMACIAS_VIEW_ANY = 'farmacias:view.any';
  case FARMACIAS_VIEW_RELATED = 'farmacias:view.related';
  case FARMACIAS_UPDATE_ANY = 'farmacias:update.any';
  case FARMACIAS_UPDATE_RELATED = 'farmacias:update.related';
  case FARMACIAS_DELETE_ANY = 'farmacias:delete.any';
  case FARMACIAS_DELETE_RELATED = 'farmacias:delete.related';

  case RUTAS_CREATE_ANY = 'rutas:create.any';
  case RUTAS_CREATE_RELATED = 'rutas:create.related';
  case RUTAS_VIEW_ANY = 'rutas:view.any';
  case RUTAS_VIEW_RELATED = 'rutas:view.related';
  case RUTAS_UPDATE_ANY = 'rutas:update.any';
  case RUTAS_UPDATE_RELATED = 'rutas:update.related';
  case RUTAS_DELETE_ANY = 'rutas:delete.any';
  case RUTAS_DELETE_RELATED = 'rutas:delete.related';
}
