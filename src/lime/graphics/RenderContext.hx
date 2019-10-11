package lime.graphics;


import lime.graphics.CanvasRenderContext;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.FlashRenderContext;
import lime.graphics.GLRenderContext;


enum RenderContext {
	
	OPENGL (gl:#if (!flash || display) GLRenderContext #else Dynamic #end);
	CANVAS (context:CanvasRenderContext);
	FLASH (stage:#if ((!js && !html5) || display) FlashRenderContext #else Dynamic #end);
	CAIRO (cairo:#if ((!js && !html5) || display) CairoRenderContext #else Dynamic #end);
	CONSOLE (context:#if ((!js && !html5) || display) ConsoleRenderContext #else Dynamic #end);
	CUSTOM (data:Dynamic);
	NONE;
	
}