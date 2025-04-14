var duration = 2;
var speed = 20;
var delay_seconds = 1;
var num_triangles = 3;


async function startProgram() {
	for (var _i0 = 0; _i0 < num_triangles; ++_i0) {
		await roll(0, speed, duration);
		await delay(delay_seconds);
		await roll(120, speed, duration);
		await delay(delay_seconds);
		await roll(240, speed, duration);
		await delay(delay_seconds);
	}
	exitProgram();
}
