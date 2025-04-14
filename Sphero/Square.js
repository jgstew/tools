var duration = 2;
var speed = 30;
var num_squares = 3;
var delay_seconds = 0;


async function startProgram() {
	for (var _i0 = 0; _i0 < num_squares; ++_i0) {
		await roll(0, speed, duration);
		await delay(delay_seconds);
		await roll(90, speed, duration);
		await delay(delay_seconds);
		await roll(180, speed, duration);
		await delay(delay_seconds);
		await roll(270, speed, duration);
		await delay(delay_seconds);
	}
	exitProgram();
}
