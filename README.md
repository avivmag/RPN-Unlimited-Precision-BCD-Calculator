# RPN-Unlimited-Precision-BCD-Calculator

A simple Reverse Polish notation (RPN) calculator for unlimited-precision unsigned integers, represented in Binary Coded Decimal (BCD).

The development of this calculator was done as part of an assignment in "Computer Architecture" course at Ben-Gurion University in the second semester of 2016.

A detailed description of the calculator can be found in the assignment desciption attached or on the links below.

## Getting Started
### Prerequisites

1. Kubuntu - this program was tested only on kubuntu, but it probably can be ran on any other known nasm and gcc compatible operating systems.
	https://kubuntu.org/getkubuntu/</br>
(The followings are for those who want to compile the files themselves)
2. GNU make
	https://www.gnu.org/software/make/
3. gcc compiler
	via ```sudo apt-get install gcc-4.8``` on ubuntu based os (kubuntu included).
4. nasm compiler
	via ```sudo apt-get install nasm``` on ubuntu based os (kubuntu included).
	
Note: this is how I used to build and run the program. There are many other well-known compilers to compile this assembly file for other types of operating systems.

### Running calculator

1. open terminal and navigate to the program directory
2. Do this step only if simulation rebuilt is needed: type `make` and press enter.
3. type `./calc.bin` and press enter.
4. enjoy :D.

## Built With

* [GNU make](https://www.gnu.org/software/make/) - A framework used for simple code compilation.
* [gcc](https://gcc.gnu.org/)
* [nasm](http://www.nasm.us/)

## Useful links

* The original source of the assignment: https://www.cs.bgu.ac.il/~caspl162/Assignments/Assignment_2.
