#include <iostream>
#include <string>
#include <vector>
#include <stdlib.h>

using namespace std;

void rotate_image(vector<string> &image, int &W, int &H)
{
  vector<string> temp;
  for(int x = 0; x < W; ++x)
  {
    string line;
    for(int y = H - 1; y >= 0; --y)
    {
      line += (x < image[y].size() ? image[y][x] : ' ');
    }
    temp.push_back(line);
  }
  image.swap(temp);
  W = H;
  H = image.size();
}

int main(int argc, char **argv)
{
  string line;

  getline(cin, line);
  int R = atoi(line.c_str());

  vector<string> image;
  int W = 0;
  while(getline(cin, line))
  {
    image.push_back(line);
    W = max(W, (int)line.length());
  }
  int H = (int)image.size();

  int rot_iter = (R / 90) % 4;
  if (rot_iter < 0) rot_iter += 4;
  for(int i = 0; i < rot_iter; ++i)
    rotate_image(image, W, H);

  for(size_t i = 0; i < image.size(); ++i)
    cout << image[i] << endl;

  return 0;
}
