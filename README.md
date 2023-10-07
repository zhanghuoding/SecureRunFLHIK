# SecureRunFLHIK

xxx_make.sh文件负责各个程序的编译工作，编译后会生成可执行文件，名为xxx或者xxx.exe。其中的xxx是源程序的名称。例如：flex_make.sh文件负责flex源文件的编译工作。该脚本文件不需要人为运行，只需要将其复制到scripts文件夹下,creatRunSHELL.sh脚本会执行该xxx_make.sh文件。

creatRunSHELL.sh脚本执行需要3个必须参数，一个可选参数。命令格式如下：
$./creatRunSHELL.sh    <program name>  <version>  <test case file name>   [run type]
例如：
$./creatRunSHELL.sh    sed  1  v1_2.universe   D_t
其中，sed为sed软件包的名字；"1”表示编译sed/versions.alt/versions.orig/v1中的源代码（对应的sed/versions.alt/versions.seeded/v1中的源代码也会被编译，后付解释）；v1_2.universe表示使用sed/testplans.alt/v1中的v1_2.universe测试用例文件进行测试；D_t是指脚本的运行模式（关于脚本运行模式，参看第三部分说明。注意！！！如果无特殊需要，请不要设置该参数）。

creatRunSHELL.sh脚本执行时，会将同文件夹下的xxx_make.sh文件复制到源代码目录中，并执行该文件以生成可执行文件，之后将可执行文件复制到程序根目录下的source目录中。之后，本脚本分析测试用例文件，并在同目录下生成名为xxx_Run.sh的脚本文件（该脚本文件中列出了进行程序测试所要执行的所有命令、以及对系统设置临时环境变量）,xxx_Run.sh脚本会被creatRunSHELL.sh脚本调用而自动执行。同时会生成名为compareFile的文件，其中列出了将已内置错误的程序和原正确程序测试结果进行比较的命令行语句。

creatRunSHELL.sh脚本会自动编译和执行各个版本程序（其中seeded版本代码会被按照FaultSeeds.h头文件中的错误种子数量，分成多个源代码文件夹，并命名为sed/versions.alt/versions.seeded/vX_FS_vx格式的目录），并将程序输出文件移动到outputs.alt目录下的相应目录中保存。

creatRunSHELL.sh脚本会在所有测试命令完成之后，按照compareFile文件，比较已内置错误的程序和原正确程序的每个输出文件，并将比较结果以矩阵的形式存储在result/vX文件夹中，并命名为"programName.vX_fault-matrix_testCaseFileName"。