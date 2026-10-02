<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Bridge SVG examples</title>
  <style>
    body { margin: 2rem auto; padding: 0 1rem; max-width: 50rem; font-family: sans-serif; }
    img { display: block; max-width: 100%; height: auto; margin: 1rem 0 2rem; }
  /* Local full/PostScript names help Chrome resolve installed DejaVu fonts.
   No font bytes or remote downloads are included. */
/* Batik does not support local() font sources; browsers opt in via @supports. */

    @font-face {
        font-family: "DejaVu Sans Mono";
        src: local("DejaVu Sans Mono"), local("DejaVuSansMono"), local("DejaVu Sans Mono Book");
        font-weight: 400;
        font-style: normal;
    }
    @font-face {
        font-family: "DejaVu Sans";
        src: local("DejaVu Sans"), local("DejaVuSans"), local("DejaVu Sans Book");
        font-weight: 400;
        font-style: normal;
    }

  </style>
  <link rel="stylesheet" href="../assets/css/bridge_svg.css">
</head>
<body>
  <h1>SVG Bridge diagrams</h1>
  <p>To display in web page, they must be inlined to pick up the CSS</p>
  <h2>Full deal</h2>
  <cfoutput>#FileRead( ExpandPath("svg_sample.svg"))#</cfoutput>
  <h2>Single hand</h2>
  <cfoutput>#FileRead( ExpandPath("svg_sample_inline.svg"))#</cfoutput>
  
</body>
</html>
