<!DOCTYPE html>
<html>

<head>
  <meta charset="utf-8">
  <title>Medrush Orders</title>
  <style>
    * {
      box-sizing: border-box;
    }

    html,
    body {
      font-family: sans-serif;
      margin: 0;
      padding: 0;
    }

    .page {
      /*
      width: 139mm;
      height: 200mm;
      background-color: #eeeeee;
      border: solid 2px #0099ff;
      */
      width: 131mm;
      height: 192mm;
      padding: 8mm;
      position: relative;
    }

    .page-break {
      page-break-after: always;
      display: inline-block;
      width: 0;
      height: 0;
    }

    h1 {
      font-size: 24pt;
      margin-bottom: 20pt;
    }

    p {
      font-size: 12pt;
      line-height: 1.5;
      margin-bottom: 10pt;
    }

    .medrush-logo {
      text-align: center;
    }

    .medrush-logo img {
      display: inline-block;
      width: 64px;
      overflow: hidden;
      background-size: cover;
    }

    .barcode {
      text-align: center;
    }

    .barcode img {
      height: 64px;
      overflow: hidden;
      background-size: cover;
    }
  </style>
</head>

<body>

  @foreach ($pagesData as $index => $page)
    <div class="page">
      <div class="medrush-logo">
        @php
          $logoPath = public_path('storage/img/logo.jpg');
          $logoExists = file_exists($logoPath);
        @endphp
        @if($logoExists)
          <img src="{{ $logoPath }}" alt="Medrush">
        @endif
      </div>

      <div>
        <h1>MEDRUSH</h1>
      </div>
      <hr>

      <div>
        <p>DESTINATARIO:</p>
        <p>{{ $page['paciente_nombre'] }}</p>
        <p>{{ $page['direccion_entrega_linea_1'] }}</p>
      </div>

      <div class="barcode">
        <img src="{{ $page['codigo_barra_url'] }}">
      </div>

      <div>
        <p>ID Pedido: {{ $page['id'] }}</p>
        <p>Codigo barra: {{ $page['codigo_barra'] }}</p>
        <p>Repartidor: {{ $page['nombre_repartidor'] }}</p>
      </div>
    </div>

    @if ($index < sizeof($pagesData) - 1)
      <div class="page-break"></div>
    @endif
  @endforeach

</body>

</html>
