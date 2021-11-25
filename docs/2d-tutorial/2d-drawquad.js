// Raw WebGL code to draw a single quad. (Yes, it's this messy.)
// This code is dependent on some named HTML elements on the page.
// It was pushed to a separate file for convenience.
// Author: Stefan Gustavson (stefan.gustavson@gmail.com) 2021
// This code is in the public domain.

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

function addShaderSource(gl, shader, id) {
	var shaderScript = document.getElementById(id);
	if ((shaderScript.type == "x-shader/x-vertex") || (shaderScript.type == "x-shader/x-fragment"))
	{
		var str = "";
		var k = shaderScript.firstChild;
		while (k) {
			if (k.nodeType == Node.TEXT_NODE) {
				str += k.textContent;
			}
			k = k.nextSibling;
		}
		previous_str = gl.getShaderSource(shader); // Add to any existing source
		gl.shaderSource(shader, previous_str + str);

	} else {
		alert('Shader script type is "' + shaderScript.type + '", should be "x-shader/x-vertex" or "x-shader/x-fragment"!');
	}
}

var shaderProgram;

function initShaders() {
	var shader;

	vshader = gl.createShader(gl.VERTEX_SHADER);
	addShaderSource(gl, vshader, "shader-vs");
	gl.compileShader(vshader);

	fshader = gl.createShader(gl.FRAGMENT_SHADER);
	addShaderSource(gl, fshader, "shader-fs-hidden");
	addShaderSource(gl, fshader, "shader-fs-visible");
	gl.compileShader(fshader);
	if (!gl.getShaderParameter(fshader, gl.COMPILE_STATUS)) {
		alert("Fragment shader compilation error:\n"
		+ gl.getShaderInfoLog(fshader, 2048));
	}
	
	shaderProgram = gl.createProgram();
	gl.attachShader(shaderProgram, vshader);
	gl.attachShader(shaderProgram, fshader);

	gl.linkProgram(shaderProgram);
	if (!gl.getProgramParameter(shaderProgram, gl.LINK_STATUS)) {
		alert("Could not initialise shaders.\n"
		+ gl.getProgramParameter(fshaderProgram,  gl.COMPILE_STATUS));
	}

	gl.useProgram(shaderProgram);

	shaderProgram.vertexPositionAttribute =
		gl.getAttribLocation(shaderProgram, "position");
	gl.enableVertexAttribArray(shaderProgram.vertexPositionAttribute);

	shaderProgram.textureCoordAttribute =
		gl.getAttribLocation(shaderProgram, "texcoord");
	gl.enableVertexAttribArray(shaderProgram.textureCoordAttribute);

	shaderProgram.timeUniform =
		gl.getUniformLocation(shaderProgram, "time");
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
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(vertices),
		gl.STATIC_DRAW);
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
	gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(textureCoords),
		gl.STATIC_DRAW);
	quadVertexTextureCoordBuffer.itemSize = 2;
	quadVertexTextureCoordBuffer.numItems = 4;

	quadVertexIndexBuffer = gl.createBuffer();
	gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, quadVertexIndexBuffer);
	var quadVertexIndices = [
		0, 1, 2,
		0, 2, 3    // A single quad, made from two triangles
	];
	gl.bufferData(gl.ELEMENT_ARRAY_BUFFER, new Uint16Array(quadVertexIndices),
		gl.STATIC_DRAW);
	quadVertexIndexBuffer.itemSize = 1;
	quadVertexIndexBuffer.numItems = 6;
}

function drawScene() {
	gl.viewport(0, 0, gl.viewportWidth, gl.viewportHeight);
	gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);

	gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexPositionBuffer);
	gl.vertexAttribPointer(shaderProgram.vertexPositionAttribute,
		quadVertexPositionBuffer.itemSize, gl.FLOAT, false, 0, 0);

	gl.bindBuffer(gl.ARRAY_BUFFER, quadVertexTextureCoordBuffer);
	gl.vertexAttribPointer(shaderProgram.textureCoordAttribute,
		quadVertexTextureCoordBuffer.itemSize, gl.FLOAT, false, 0, 0);

	gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, quadVertexIndexBuffer);
	gl.uniform1f(shaderProgram.timeUniform, runningTime*0.001);
	gl.drawElements(gl.TRIANGLES, quadVertexIndexBuffer.numItems,
		gl.UNSIGNED_SHORT, 0);
}

var lastTime = 0;
var startTime = 0;
var runningTime = 0;
var fpscounter;
	
function animate() {
	frames += 1;
	var currentTime = Date.now(); // Milliseconds
	runningTime = currentTime - startTime;
	var elapsedTime = currentTime - lastTime;
	if (elapsedTime >= 1000.0) {
		fps = frames * 1000.0 / elapsedTime;
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
	var canvas = document.getElementById("psrdnoise-canvas");
	initGL(canvas);
	initShaders();
	initBuffers();
	startTime = new Date().getTime();
	gl.clearColor(0.0, 0.0, 0.0, 1.0);
	gl.enable(gl.DEPTH_TEST);
	tick();
}
