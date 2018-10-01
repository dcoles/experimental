#include <iostream>
#include <string_view>

class Hello {
public:
  explicit Hello(std::string_view name) : name(name) {}

  void say_hello() { std::cout << "Hello, " << name << "\n"; }

private:
    std::string name;
};

int main(int argc, char* argv[]) {
    Hello h("world");
    h.say_hello();
    return 0;
}
