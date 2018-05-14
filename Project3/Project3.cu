#include <iostream>
#include<stdio.h>
#include "ImageWriter.h"
#include<cuda.h>
#include <string>
#include <fstream>
using namespace std;


__global__ void kernel_MAX(int* pixelDepth)
{
	pixelDepth[0] = 222;
}
__global__ void kernel_SUM(unsigned char* voxelData,int pixelDepth)
{
}

void kernelHandler(int nRows, int nCols, int nSheets, string inFile, int projectionType)
{
	int relativeHeight;
	int relativeWidth;
	int h_relativeDepth;
	unsigned char* raw_voxelData = new unsigned char[nRows*nSheets*nCols]();
	ifstream s(inFile, ios::binary);
	s.read(reinterpret_cast<char*>(raw_voxelData), nCols*nRows*nSheets); 
	s.close();
	unsigned char* h_voxelData = new unsigned char[nRows*nSheets*nCols]();
	switch(projectionType)
	{
		case 1: //0 degree roation 0ol n = n
		relativeHeight = nRows;
		relativeWidth = nCols;
		h_relativeDepth = nSheets;
		break;
		case 2: //180 degree rotation horizontally
		relativeHeight = nRows;
		relativeWidth = nCols;
		h_relativeDepth = nSheets;
		for(int s = 0; s<nSheets;s++)
		{
			for(int i = 0; i<nCols; i++)
			{
				for(int j = 0; j<nRows;j++)
				{
					int currentSheet = j*i*s;
					int relativeValue = j+j*i;
					int originalPerspective = (nRows-j-1) + ((nRows-j-1)*(nCols-i-1));
					h_voxelData[relativeValue + currentSheet] = raw_voxelData[(nRows-j-1) + originalPerspective + currentSheet];
				}
			}
		}
		break;
		case 3: //90 degree rotation horizontally clockwise
		relativeHeight = nSheets;
		relativeWidth = nRows;
		h_relativeDepth = nCols;
		for(int s = 0; s<nSheets;s++)
		{
			for(int i = 0; i<nCols; i++)
			{
				for(int j = 0; j<nRows;j++)
				{
					int currentSheet = j*i*s;
					int relativeValue = j+j*i;
					int originalPerspective = (nRows-j-1) + ((nRows-j-1)*(nCols-i-1));
					h_voxelData[relativeValue + currentSheet] = raw_voxelData[(nRows-j-1) + originalPerspective + currentSheet];
				}
			}
		}
		break;
		case 4: //-90 degree rotation horizontally counterclockwise
		relativeHeight = nSheets;
		relativeWidth = nRows;
		h_relativeDepth = nCols;
		break;
		case 5://90 degree rotation upward
		relativeHeight = nCols;
		relativeWidth = nSheets;
		h_relativeDepth = nRows;
		break;
		case 6: // 90 degree rotation download
		relativeHeight = nCols;
		relativeWidth = nSheets;
		h_relativeDepth = nRows;
		break;
	}
	
	unsigned char *d_voxelData;
	
	int a = 5;
	int* temp = new int[1];
	temp[0] = a;
	int* d_relativeDepth;

	cout << "Before kernel: " << temp[0] << endl;

	//size_t size = nRows*nCols*nSheets*sizeof(char);
	//cudaMalloc((void**)&d_voxelData,size);
	cudaMalloc((void**)&d_relativeDepth,sizeof(int));
	//cudaMemcpy(d_voxelData,raw_voxelData,size,cudaMemcpyHostToDevice);
	cudaMemcpy(d_relativeDepth,temp,sizeof(int),cudaMemcpyHostToDevice);
	// Invoke kernel
	kernel_MAX<<<relativeWidth,relativeHeight>>>(d_relativeDepth);
	//kernel_SUM<<<relativeWidth,relativeHeight>>>(d_voxelData,temp);
	cudaDeviceSynchronize();
	// Copy result from device memory to host memory
	//cudaMemcpy(h_voxelData,d_voxelData,size,cudaMemcpyDeviceToHost);
	cudaMemcpy(temp,d_relativeDepth,sizeof(int),cudaMemcpyDeviceToHost);
	// Free device memory
	cout << "Before kernel: " << temp[0] << endl;
	cudaFree(d_relativeDepth);
}

void writeTheFile(string outFile, int xres, int yres, const unsigned char* imageBytes)
{
	unsigned char* row = new unsigned char[3*xres];
	ImageWriter *w = ImageWriter:: create(outFile,xres,yres);
	int next = 0;
	for(int r = 0; r<yres; r++)
	{
		for(int c = 0; c<3*xres; c+=3)
		{
			row[c] = row[c+1] = row[c+2] = imageBytes[next++];
		}
		w->addScanLine(row);
	}
	w->closeImageFile();
	delete w;
	delete[] row;
}

int main(int argc, char* argv[])
{
	int nRows = atoi( argv[1] );
	int nCols = atoi(argv[2]);
	int nSheets = atoi(argv[3]);
	string inFile = argv[4];
	int pt = stoi(argv[5]);
	string outFile = argv[6];
	kernelHandler(nRows,nCols,nSheets,inFile,pt);
	cudaError_t err = cudaDeviceSynchronize();
	if ( err != cudaSuccess )
	{
		printf("%s", cudaGetErrorString(err));
	}
	return 0;
}
