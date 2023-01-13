import haxepunk.*;
import haxepunk.debug.Console;
import haxepunk.input.*;
import haxepunk.input.gamepads.*;
import haxepunk.math.*;
import haxepunk.screen.UniformScaleMode;
import haxepunk.utils.*;
import openfl.Lib;
import scenes.*;


class Main extends Engine
{
    public static inline var SAVE_FILE_NAME = "underground_spring_save_file";
    public static inline var INPUT_BUFFER_SIZE = 10;

    private static var inputBuffer:Map<String, Array<Bool>>;
    private static var timeHeld:Map<String, Float>;

    public static var globalSfx:Map<String, Sfx>;

    static public function held(input:String, duration:Int) {
        var wasHeld = true;
        for(i in 0...duration) {
            if(!inputBuffer[input][i]) {
                wasHeld = false;
                break;
            }
        }
        return Input.check(input) && wasHeld;
    }

    static public function getTimeHeld(input:String) {
        return timeHeld[input];
    }

    static public function tapped(input:String, buffer:Int) {
        var wasTap = false;
        for(i in 1...(buffer + 2)) {
            if(!inputBuffer[input][i]) {
                wasTap = true;
                break;
            }
        }
        return Input.released(input) && inputBuffer[input][0] == true && wasTap;
    }

    static function main() {
        new Main();
    }

    override public function init() {
#if debug
        Console.enable();
#end
        HXP.screen.scaleMode = new UniformScaleMode(UniformScaleType.Expand);
#if desktop
        HXP.fullscreen = true;
        //Lib.application.window.resize(HXP.width * 2, HXP.height * 2);
#end

        Key.define("up", [Key.W, Key.UP]);
        Key.define("down", [Key.S, Key.DOWN]);
        Key.define("left", [Key.A, Key.LEFT, Key.LEFT_SQUARE_BRACKET]);
        Key.define("right", [Key.D, Key.RIGHT, Key.RIGHT_SQUARE_BRACKET]);
        Key.define("jump", [Key.Z]);
        Key.define("fly", [Key.C]);
        Key.define("collect", [Key.V]);
        Key.define("shoot", [Key.X]);

        inputBuffer = [
            "shoot" => [for (i in 0...INPUT_BUFFER_SIZE) false],
        ];
        timeHeld = [];

        globalSfx = [
            //"shoot" => new Sfx("audio/shoot.wav")
            //"shoot1" => new Sfx("audio/shoot1.wav"),
            //"shoot2" => new Sfx("audio/shoot2.wav"),
            //"shoot3" => new Sfx("audio/shoot3.wav"),
            //"shoot4" => new Sfx("audio/shoot4.wav"),
            //"shoot5" => new Sfx("audio/shoot5.wav"),
            //"shoot6" => new Sfx("audio/shoot6.wav")
        ];

        if(Gamepad.gamepad(0) != null) {
            defineGamepadInputs(Gamepad.gamepad(0));
        }

        Gamepad.onConnect.bind(function(newGamepad:Gamepad) {
            defineGamepadInputs(newGamepad);
        });

        HXP.scene = new GameScene();
    }

    private function defineGamepadInputs(gamepad) {
        gamepad.defineButton("up", [XboxGamepad.DPAD_UP]);
        gamepad.defineButton("down", [XboxGamepad.DPAD_DOWN]);
        gamepad.defineButton("left", [XboxGamepad.DPAD_LEFT]);
        gamepad.defineButton("right", [XboxGamepad.DPAD_RIGHT]);
        gamepad.defineAxis("up", XboxGamepad.LEFT_ANALOGUE_Y, -0.5, -1);
        gamepad.defineAxis("down", XboxGamepad.LEFT_ANALOGUE_Y, 0.5, 1);
        gamepad.defineAxis("left", XboxGamepad.LEFT_ANALOGUE_X, -0.5, -1);
        gamepad.defineAxis("right", XboxGamepad.LEFT_ANALOGUE_X, 0.5, 1);
    }

    override public function update() {
#if desktop
        if(Key.pressed(Key.ESCAPE)) {
            Sys.exit(0);
        }
#end
        super.update();

        for(input in inputBuffer.keys()) {
            inputBuffer[input].insert(0, Input.check(input));
            inputBuffer[input].pop();
        }
        for(input in timeHeld.keys()) {
            if(Input.check(input)) {
                timeHeld[input] += HXP.elapsed;
            }
            else {
                timeHeld[input] = 0;
            }
        }
    }
}
