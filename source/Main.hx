import haxepunk.*;
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

    private static var inputBuffer:Map<String, Array<Bool>>;

    static function main() {
        new Main();
    }

    override public function init() {
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
        Key.define("shoot", [Key.X]);

        inputBuffer = [
            "jump" => [for (i in 0...10) false],
            "shoot" => [for (i in 0...10) false],
            "fly" => [for (i in 0...10) false],
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

    static public function inputPressedBuffer(input:String, frames:Int) {
        if(Input.pressed(input)) {
            return true;
        }
        for(i in 0...frames) {
            if(inputBuffer[input][i]) {
                return true;
            }
        }
        return false;
    }


    override public function update() {
#if desktop
        if(Key.pressed(Key.ESCAPE)) {
            Sys.exit(0);
        }
#end
        super.update();

        for(input in inputBuffer.keys()) {
            inputBuffer[input].insert(0, Input.pressed(input));
            inputBuffer[input].pop();
        }
    }
}
