import sys
class CatchOut:
  def __init__(self):
    self.value = ''
  def write(self, txt):
    self.value += txt
  def print(self):
    temp = self.value;
    self.value="";
    return temp;
catchOut = CatchOut()
sys.stdout = catchOut
sys.stderr = catchOut
