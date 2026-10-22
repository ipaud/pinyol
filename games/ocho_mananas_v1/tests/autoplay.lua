-- Plays the calls like a perfect player: taps every circle when it is due, follows the sliders, circles the spinner.
-- Loaded by the test scripts (lua require("tests.autoplay").install()).
local autoplay = {}

function autoplay.install()
  local real = pen
  pen = function()
    if state == "chant" then
      local x, y, down, tapped, released = chant.finger()
      if x then return x, y, down, tapped, released end
    end
    return real()
  end
  autoplay.real = real
end

function autoplay.remove() if autoplay.real then pen = autoplay.real end end

return autoplay
