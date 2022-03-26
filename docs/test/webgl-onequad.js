	// Raw WebGL code to draw a single quad.
	// Ugh. So much boilerplate code.

    var gl;

    function initGL(canvas) {
        try {
            gl = canvas.getContext("experimental-webgl");
			gl.viewportWidth = canvas.width;
            gl.viewportHeight = canvas.height;
			gl.getExtension("OES_standard_derivatives");
        } catch (e) {
        }
        if (!gl) {
            alert("Could not initialise WebGL, sorry :-(");
        }
    }

    function getShader(gl, id) {
        var shaderScript = document.getElementById(id);
        if (!shaderScript) {
            return null;
        }

        var str = "";
        var k = shaderScript.firstChild;
        while (k) {
            if (k.nodeType == 3) {
                str += k.textContent;
            }
            k = k.nextSibling;
        }

        var shader;
        if (shaderScript.type == "x-shader/x-fragment") {
            shader = gl.createShader(gl.FRAGMENT_SHADER);
        } else if (shaderScript.type == "x-shader/x-vertex") {
            shader = gl.createShader(gl.VERTEX_SHADER);
        } else {
            return null;
        }

        gl.shaderSource(shader, str);
        gl.compileShader(shader);

        if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
            alert(gl.getShaderInfoLog(shader));
            return null;
        }

        return shader;
    }

    var shaderProgram;

    function initShaders() {

        var vertexShader = getShader(gl, "shader-vs");
        var fragmentShader = getShader(gl, "shader-fs");

        shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
            alert("Could not initialise shaders");
        }

        gl.useProgram(shaderProgram);

        shaderProgram.vertexPositionAttribute = gl.getAttribLocation(shaderProgram, "position");
        gl.enableVertexAttribArray(shaderProgram.vertexPositionAttribute);

        shaderProgram.textureCoordAttribute = gl.getAttribLocation(shaderProgram, "texcoord");
        gl.enableVertexAttribArray(shaderProgram.textureCoordAttribute);

        shaderProgram.timeUniform = gl.getUniformLocation(shaderProgram, "time");
    }

    var quadVertexPositionBuffer;
    var quadVertexTextureCoordBuffer;
    var quadVertexIndexBuffer;

    function initBuffers() {
        quadVertexPositionBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexPositionBuffer);
        vertices = [
            // One single immovable quad covering the view
            -1.0, -1.0,  0.0,
             1.0, -1.0,  0.0,
             1.0,  1.0,  0.0,
            -1.0,  1.0,  0.0,
		];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices), gl.STATIC_DRAW);
        quadVertexPositionBuffer.itemSize = 3;
        quadVertexPositionBuffer.numItems = 4;

        quadVertexTextureCoordBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexTextureCoordBuffer);
        var textureCoords = [
          // Map unit square onto the single quad
          0.0, 0.0,
          1.0, 0.0,
          1.0, 1.0,
          0.0, 1.0,
        ];
        gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(textureCoords), gl.STATIC_DRAW);
        quadVertexTextureCoordBuffer.itemSize = 2;
        quadVertexTextureCoordBuffer.numItems = 4;

        quadVertexIndexBuffer = gl.createBuffer();
        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, quadVertexIndexBuffer);
        var quadVertexIndices = [
            0, 1, 2,      0, 2, 3    // A single quad, made from two triangles
        ];
        gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(quadVertexIndices), gl.STATIC_DRAW);
        quadVertexIndexBuffer.itemSize = 1;
        quadVertexIndexBuffer.numItems = 6;
    }

    function drawScene() {
        gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);
        gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

        gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexPositionBuffer);
        gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute, quadVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexTextureCoordBuffer);
        gl.vertexAttribPointer(shaderProgram.textureCoordAttribute, quadVertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0);

        gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, quadVertexIndexBuffer);
		gl.uniform1f(shaderProgram.timeUniform, runningTime*0.001);
        gl.drawElements(gl.TRIANGLES, quadVertexIndexBuffer.numItems, gl.UNSIGNED_SHORT, 0);
    }

    var lastTime = 0;
    var startTime = 0;
	var runningTime = 0;
	var fpscounter;
	
    function animate() {
		frames += 1;
        var currentTime = new Date().getTime(); // Milliseconds
		runningTime = currentTime - startTime;
        var elapsedTime = currentTime - lastTime;
		if (elapsedTime >= 1000.0) {
			fps = frames * 1000 / elapsedTime;
			fpscounter.value = Math.round(fps*10)/10;
			frames = 0;
			lastTime = currentTime;
		}
    }

    function tick() {
        requestAnimationFrame(tick);
        animate();
        drawScene();
    }

    function webGLStart() {
		fpscounter = document.getElementById("fpscounter");
        var canvas = document.getElementById("Noisedemo-canvas");
        initGL(canvas);
        initShaders();
        initBuffers();
		startTime = new Date().getTime();
        gl.clearColor(0.0, 0.0, 0.0, 1.0);
        gl.enable(gl.DEPTH_TEST);
        tick();
    }
