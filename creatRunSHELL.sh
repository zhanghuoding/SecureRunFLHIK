#!/bin/bash

####请务必将本文件放在程序根目录下的scripts目录下！

#测试用例文件解析请参看http://sir.unl.edu/content/mts-usage.php#stypes


#脚本执行格式：creatRunSHELL.sh <可执行程序名> <欲编译程序版本> <测试用例文件名> <脚本文件执行模式>
#<可执行程序名>	是必须参数。该参数名称只可以为主程序名，如flex grep make等等，不可以带后缀，如flex.exe flex.c grep_a等等都是错误的
#<欲编译程序版本>	是必须参数，告诉脚本想要编译的源代码的版本，形如：0  1  2等等。一次只可指定一个版本。
#<测试用例文件名>	是必须参数（除非修改本脚本），指出将要执行的测试用例文件名
#		例如：v0.tsl.universe.v0.cov.universe
#		也可以编辑本文件，在数组testPlans_file_array中指明测试用例文件的相对或绝对路径
#<脚本文件执行模式>是可选参数，告诉脚本本次要执行的模式，模式共有六种，分别是：R|D|d|T|D_t|d_t  也可以不设置模式，程序自动执行默认的R模式


#调用该脚本时，可以添加命令 2> 错误信息文件名 > 标准输出文件名  对脚本执行时的输出重定向到文件
#例如：命令creatRunSHELL.sh flex v0.tsl.universe 2> errorFile > outputFile
#上例会将出错信息输出到errorFile文件，而不在终端显示；将普通提示信息输出到outputFile文件，而不再终端显示。


#注：本脚本文件需要放在程序目录的/scripts/目录下。例如放在flex/scripts/目录下
#echo ============================================****说明****===================================================
#echo  "本脚本文件执行有6种模式供选择。分别是：R|D|d|T|D_t|d_t  即runall, runall-and-diff using cmp, runall-and-diff using diff, trace, runall-and-diff-time script using cmp和runall-and-diff-time script using diff"
#echo  ""
#echo  "runall(R)					：只按照测试用例逐条执行，并将输出结果文件保存在特定目录下。"
#echo  "runall-and-diff using cmp(D)			：执行runall之后，用cmp -s命令比较上次进行测试时的输出文件和本次文件的不同之处。"
#echo  "runall-and-diff using diff(d)			：执行runall之后，用diff -r命令比较上次进行测试时的输出文件和本次文件的不同之处。"
#echo  "trace(T)					：执runal同时，它的目的是执行一个仪表化的可执行文件，并在每次执行之后保存为该可执行文件创建的跟踪文件。"
#echo  "runall-and-diff-time script using cmp(D_t)	：执行runall-and-diff using cmp的同时，收集每条测试所花费的时间。"
#echo  "runall-and-diff-time script using diff(d_t)	：执行runall-and-diff using diff的同时，收集每条测试所花费的时间。"
#echo ==========================================================================================================
#echo  ""
#echo  ""

################################判断参数个数############################

if test $# -lt 3
then
	echo 执行本脚本必须要3个参数，请阅读脚本注释
	exit
fi

######################################################################


basepath=$(cd `dirname $0`; pwd)
basepath=${basepath%/*}
readonly basepath
experiment_root=${basepath%/*}

tempProgramName=$1
programName=$tempProgramName
runSHELL=$basepath/scripts/${tempProgramName}_Run.sh
readonly runSHELL

sourceCodeVersion=$2
readonly sourceCodeVersion

seedVersionCount=1

##############################建立错误源代码####################################
creatFaultSeed(){

seedVersionCount=1
if [[ -e "$basepath/versions.alt/versions.seeded/v$sourceCodeVersion/FaultSeeds.h" ]]
then
	while read seedLine
	do
		if [[ -z $seedLine ]]
		then
			continue
		fi
		mkdir -p $basepath/versions.alt/versions.seeded/v${sourceCodeVersion}_FS_v$seedVersionCount
		cp -r $basepath/versions.alt/versions.seeded/v$sourceCodeVersion/*  $basepath/versions.alt/versions.seeded/v${sourceCodeVersion}_FS_v$seedVersionCount/
		seedLine=${seedLine#*define}
		seedLine=${seedLine%\*/*}
		seedLine="#define"$seedLine
		printf "$seedLine" > $basepath/versions.alt/versions.seeded/v${sourceCodeVersion}_FS_v$seedVersionCount/FaultSeeds.h

		seedVersionCount=$(( $seedVersionCount + 1 ))
	done < $basepath/versions.alt/versions.seeded/v$sourceCodeVersion/FaultSeeds.h
else
	echo "错误种子文件$basepath/versions.alt/versions.seeded/v$sourceCodeVersion/FaultSeeds.h不存在！请检查！"
fi

readonly seedVersionCount

}
####################################################################################

origOrSeeded=
sourceCodeDir=
seedVersion=

####################################编译源代码（正/误）版本######################################
makeSource(){
tempProgramName=${programName%.exe*}
origOrSeeded=
sourceCodeDir=
if [[ x$1 == x"0" ]]
then
	origOrSeeded=versions.orig
	sourceCodeDir=v$sourceCodeVersion
elif [[ x$1 == x"1" ]]
then
	origOrSeeded=versions.seeded
	sourceCodeDir=v${sourceCodeVersion}_FS_v$seedVersion
else
	echo 发生未知错误，请重试！
fi

if [[ -e ${tempProgramName}_make.sh ]]
then
	cp $basepath/scripts/${tempProgramName}_make.sh  $basepath/versions.alt/$origOrSeeded/$sourceCodeDir
	chmod +x $basepath/versions.alt/$origOrSeeded/$sourceCodeDir/${tempProgramName}_make.sh
	cd $basepath/versions.alt/$origOrSeeded/$sourceCodeDir
	source ./${tempProgramName}_make.sh
else
	cd $basepath/versions.alt/$origOrSeeded/$sourceCodeDir
	make
fi

cd $basepath/scripts

if [[ -e $basepath/versions.alt/$origOrSeeded/$sourceCodeDir/$tempProgramName ]]
then
	cp $basepath/versions.alt/$origOrSeeded/$sourceCodeDir/$tempProgramName  $basepath/source/
elif [[ -e $basepath/versions.alt/$origOrSeeded/$sourceCodeDir/${tempProgramName}.exe ]]
then
	tempProgramName=${tempProgramName}.exe
	cp $basepath/versions.alt/$origOrSeeded/$sourceCodeDir/${tempProgramName} $basepath/source/
else
	echo 无法找到可执行文件！
	exit
fi
programName=$tempProgramName
tempProgramName=

}
#######################################################################################


suffixD="cmp -s"
readonly suffixD
suffixd="diff -r"
readonly suffixd

tesFi=$3
testPlansFile="$basepath/testplans.alt/v$sourceCodeVersion/"$tesFi
if [ ! -e $testPlansFile ]
then
	testPlansFile="$basepath/testplans.alt/"$tesFi
fi
readonly testPlansFile

run_type=$4

parameter=$5$6
readonly parameter


testPlans_file_array=($testPlansFile)


##########################输入模式########################
if [[ x$run_type == x"R"  ]] || [[ x$run_type == x"D"  ]] || [[ x$run_type == x"d"  ]] || [[ x$run_type == x"T"  ]] || [[ x$run_type == x"D_t"  ]] || [[ x$run_type == x"d_t"  ]]
then
	echo "脚本将按照$run_type模式执行"
else
	echo 您未输入脚本执行模式，脚本将按照默认R模式执行
	run_type=R
fi
###########################################################

cmdParameter=NULL
lastParameter=NULL
lastLastParameter=NULL
cmdRun=NULL
cmdF1=
cmdF2=
cmdT1=
cmdLineOrg=
tempCmd1=
tempExcutT=

emptyLine=false

cmdExcut=(" " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " " ")
cmdExcutSize=21
readonly cmdExcutSize

cmdExcutParaP=7
readonly cmdExcutParaP
cmdExcutIndexP=$cmdExcutParaP

cmdExcutParaS=0
readonly cmdExcutParaS
cmdExcutIndexS=$cmdExcutParaS

cmdExcutParaF=11
readonly cmdExcutParaF
cmdExcutIndexF=$cmdExcutParaF

cmdExcutParaX=16
readonly cmdExcutParaX
cmdExcutIndexX=$cmdExcutParaX

cmdExceptRTypeExcut=(" " " " " " " " " " " " " " " " " " " " " " " " " " " " " ")
cmdExceptRTypeExcutSize=15
readonly cmdExceptRTypeExcutSize
cmdExceptRTypeExcutPara1=0
readonly cmdExceptRTypeExcutPara1
cmdExceptRTypeExcutIndex1=$cmdExceptRTypeExcutPara1
cmdExceptRTypeExcutPara2=5
readonly cmdExceptRTypeExcutPara2
cmdExceptRTypeExcutIndex2=$cmdExceptRTypeExcutPara2
cmdExceptRTypeExcutPara3=10
readonly cmdExceptRTypeExcutPara3
cmdExceptRTypeExcutIndex3=$cmdExceptRTypeExcutPara3

para_s=(" " " " " " " " " ")
para_sSize=5
readonly para_sSize
para_sIndex=0

para_x=(" " " " " " " " " ")
para_xSize=5
readonly para_xSize
para_xIndex=0

testFileNa=

#################################测试用例文件分析函数##########################################

echoTextFun(){
	echo $*
}

reset(){

	cmdParameter=NULL
	lastParameter=NULL
	lastLastParameter=NULL
	cmdRun=NULL
	cmdT1=
	tempCmd1=
	tempExcutT=
	ii=0
	while [ $ii -lt $cmdExcutSize ]
	do
		cmdExcut[$ii]=" "
		ii=$(( $ii + 1 ))
	done

	cmdExcutIndexP=$cmdExcutParaP
	cmdExcutIndexS=$cmdExcutParaS
	cmdExcutIndexF=$cmdExcutParaF
	cmdExcutIndexX=$cmdExcutParaX

	emptyLine=false
	
	ii=0
	while [ $ii -lt $cmdExceptRTypeExcutSize ]
	do
		cmdExceptRTypeExcut[$ii]=" "
		ii=$(( $ii + 1 ))
	done
	cmdExceptRTypeExcutIndex1=$cmdExceptRTypeExcutPara1
	cmdExceptRTypeExcutIndex2=$cmdExceptRTypeExcutPara2
	cmdExceptRTypeExcutIndex3=$cmdExceptRTypeExcutPara3

	ii=0
	while [ $ii -lt $para_sSize ]
	do
		para_s[$ii]=" "
		para_x[$ii]=" "
		ii=$(( $ii + 1 ))
	done
	para_sIndex=0
	para_xIndex=0
}

reallExcut(){
	if [[ ${#tempExcutT} -gt 1 ]]
	then
#		if [[ `expr index "$tempExcutT" "/"` != 0 ]]
#		then
#			tempDir=$tempExcutT
#			tempDir=${tempDir##*../}
#			tempDir=${tempDir%/*}
#			mkdir -p $basepath/${tempDir}/
#		fi
		per=`expr index "${tempExcutT}" %`
		pend=${#tempExcutT}
		if [ $per != 0 ]
		then
			bef=
			per=$(( $per - 1 ))
			bef=${tempExcutT:0:$per}
			bef=${bef}"%%"
			per=$(( $per + 1 ))
			pend=$(( $pend - $per ))
			bef=${bef}${tempExcutT:$per:$pend}
			tempExcutT=$bef
		fi
		printf  "${tempExcutT}\n" >> $runSHELL
	fi
	tempExcutT=
}

excut(){
	tempExcutT='#command :'$cmdLineOrg
	reallExcut

#将错误信息和标准输出都捆绑到一起
	cmdExcut[$cmdExcutParaP]=${cmdExcut[$cmdExcutParaP]}" 2>&1"

	j=$cmdExceptRTypeExcutPara1
	k=$cmdExceptRTypeExcutPara2
	f=$cmdExceptRTypeExcutPara3
	if [[ "x$run_type" != "xR" ]]
	then
		while [ $j -lt $cmdExceptRTypeExcutIndex1 ]
		do
			tempExcutT=${cmdExceptRTypeExcut[$j]}
			reallExcut
			j=$(( $j + 1 ))
		done
	fi

	for sFile in ${para_s[@]}
	do
		if [[ x$sFile == x" " ]]
		then
			continue
		fi
		while read sLine
		do
			tempExcutT=$sLine
			reallExcut
		done < $sFile
	done

	cmdLineOrg=
	ii=0

	while [ $ii -lt $cmdExcutSize ]
	do
		tempExcutT=${cmdExcut[$ii]}
		reallExcut
		ii=$(( $ii + 1 ))
	done

	if [[ "x$run_type" != "xR" ]]
	then
		while [ $k -lt $cmdExceptRTypeExcutIndex2 ]
		do
			tempExcutT=${cmdExceptRTypeExcut[$k]}
			reallExcut
			k=$(( $k + 1 ))
		done
	fi
	
	for xFile in ${para_x[@]}
	do
		if [[ x$xFile == x" " ]]
		then
			continue
		fi
		while read xLine
		do
			tempExcutT=$xLine
			reallExcut
		done < $xFile
	done

	if [[ "x$run_type" != "xR" ]]
	then
		while [ $f -lt $cmdExceptRTypeExcutIndex3 ]
		do
			tempExcutT=${cmdExceptRTypeExcut[$f]}
			reallExcut
			f=$(( $f + 1 ))
		done
	fi
}

parseCmd(){
	cmdParameter=NULL
	cmdRun=NULL
	tmpCmdString=$tempCmd1
	tempCmd1=

	tmpCmdString=${tmpCmdString#*-}
	cmdParameter=${tmpCmdString%%[*}

	if [[ `expr index "$cmdParameter" C` != 0 ]];then
		cmdParameter="C"
	elif [[ `expr index "$cmdParameter" F` != 0 ]];then
		cmdParameter="F"
	elif [[ `expr index "$cmdParameter" I` != 0 ]];then
		cmdParameter="I"
	elif [[ `expr index "$cmdParameter" O` != 0 ]];then
		cmdParameter="O"
	elif [[ `expr index "$cmdParameter" P` != 0 ]];then
		cmdParameter="P"
	elif [[ `expr index "$cmdParameter" S` != 0 ]];then
		cmdParameter="S"
	elif [[ `expr index "$cmdParameter" X` != 0 ]];then
		cmdParameter="X"
	elif [[ `expr index "$cmdParameter" s` != 0 ]];then
		cmdParameter="s"
	elif [[ `expr index "$cmdParameter" x` != 0 ]];then
		cmdParameter="x"
	fi

	tmpCmdString=${tmpCmdString#*[}
	cmdRun=$tmpCmdString

	if [[ ${#cmdRun} -le 0 ]]
	then
		cmdParameter=NULL
		cmdRun=NULL
	fi
}

runallType(){
	case $cmdParameter in
		C) #echo 当前是C参数：	$cmdRun
			tempExcutT="#"$cmdRun
			reallExcut
		;;
		F) #echo 当前是F参数：	$cmdRun

			cmdF1=${cmdRun%|*}
			cmdF2=${cmdRun#*|}
			
			if [[ $cmdExcutIndexF -ge $cmdExcutParaX ]]
			then
				echoTextFun 该条命令参数太多，已被截断。执行结果可能不正确！
			else
				cmdExcut[$cmdExcutIndexF]="mv $basepath/scripts/$cmdF1 $basepath/outputs/$cmdF2"
				cmdExcutIndexF=$(( $cmdExcutIndexF + 1 ))
			fi
			unset cmdF1
			unset cmdF2
		;;
		I) #echo 当前是I参数：	$cmdRun
			if [[ ${cmdExcut[$cmdExcutParaP]} != " " ]]
			then
				tempI1=${cmdExcut[$cmdExcutParaP]}
				cmdI1=${tempI1%>*}
				cmdI2=${tempI1#*>}

				cmdExcut[$cmdExcutParaP]=$cmdI1" < $basepath/inputs/"$cmdRun"  >  "$cmdI2
				unset tempI1
				unset cmdI1
				unset cmdI2
			else
				cmdExcut[$cmdExcutParaP]="$basepath/source/$programName  < $basepath/inputs/$cmdRun > $basepath/outputs/t$num"
			fi
		;;
		O) #echo 当前是O参数：	$cmdRun
			tempO1=${cmdExcut[$cmdExcutParaP]}
			cmdO1=${tempO1%>*}
			cmdExcut[$cmdExcutParaP]=$cmdO1" > $basepath/outputs/"$cmdRun
			unset tempO1
			unset cmdO1
		;;
		P) #echo 当前是P参数：	$cmdRun
			cmdExcut[$cmdExcutParaP]="$basepath/source/$programName $cmdRun > $basepath/outputs/t$num "
		;;
		S) #echo 当前是S参数：	$cmdRun
			
			if [[ $cmdExcutIndexS -ge $cmdExcutParaP ]]
			then
				echoTextFun 该条命令参数太多，已被截断。执行结果可能不正确！
			else
				cmdExcut[$cmdExcutIndexS]="$basepath/testplans.alt/testscripts/"$cmdRun
				tempNeedChs=${cmdExcut[$cmdExcutIndexS]%% *}
				chmod +x $tempNeedChs
				cmdExcutIndexS=$(( $cmdExcutIndexS + 1 ))
			fi
		;;
		X) #echo 当前是X参数：	$cmdRun
			
			if [[ $cmdExcutIndexX -ge $cmdExcutSize ]]
			then
				echoTextFun 该条命令参数太多，已被截断。执行结果可能不正确！
			else
				cmdExcut[$cmdExcutIndexX]="$basepath/testplans.alt/testscripts/"$cmdRun
				tempNeedChx=${cmdExcut[$cmdExcutIndexX]%% *}
				chmod +x $tempNeedChx
				cmdExcutIndexX=$(( $cmdExcutIndexX + 1 ))
			fi
		;;
		s) #echo 当前是s参数：	$cmdRun
			if [[ $para_sIndex -ge $para_sSize ]]
			then
				echoTextFun 该条命令参数太多，已被截断。执行结果可能不正确！
			else
				para_s[$para_sIndex]="$basepath/testplans.alt/testscripts/"$cmdRun
				para_sIndex=$(( $para_sIndex + 1 ))
			fi
		;;
		x) #echo 当前是x参数：	$cmdRun
			if [[ $para_xIndex -ge $para_xSize ]]
			then
				echoTextFun 该条命令参数太多，已被截断。执行结果可能不正确！
			else
				para_x[$para_xIndex]="$basepath/testplans.alt/testscripts/"$cmdRun
				para_xIndex=$(( $para_xIndex + 1 ))
			fi
		;;
		*) echoTextFun 该行命令中的参数不匹配，请检查！
		;;
		esac
}
runTypeD_d(){
	tempD2="$basepath/oldoutputs/"
	suffix=
	
	if [[ x$1 == "xD" ]]
	then
		suffix=$suffixD
	else
		suffix=$suffixd
	fi
	tempD3=${cmdExcut[$cmdExcutParaP]}
	tempD4=${tempD3##*outputs/}
	cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex2]="$suffix $basepath/outputs/$tempD4  $tempD2$tempD4"
	cmdExceptRTypeExcutIndex2=$(( $cmdExceptRTypeExcutIndex2 + 1 ))
	
	if [[ $cmdExcutIndexF != $cmdExcutParaF ]]
	then
		m=$cmdExcutParaF
		while [[ $m -lt $cmdExcutIndexF ]]
		do
			tempD5=${cmdExcut[$m]}
			tempD6=${tempD5##*outputs/}

			cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex2]="$suffix $basepath/outputs/$tempD6  $tempD2$tempD6"
			cmdExceptRTypeExcutIndex2=$(( $cmdExceptRTypeExcutIndex2 + 1 ))
			m=$(( $m + 1 ))
		done
	fi
}

runTypeD_t_d_t(){
	cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex1]="set t=\`mydate\`"
	cmdExceptRTypeExcutIndex1=$(( $cmdExceptRTypeExcutIndex1 + 1 ))
	cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex1]='echo "Start time = ${t}"'
	cmdExceptRTypeExcutIndex1=$(( $cmdExceptRTypeExcutIndex1 + 1 ))

	tempt1=$1
	tempt2=${tempt1%_t}
	tempt2=${tempt2#* }
	
	runTypeD_d $tempt2

	cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex3]="set t=\`mydate\`"
	cmdExceptRTypeExcutIndex3=$(( $cmdExceptRTypeExcutIndex3 + 1 ))
	cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex3]='echo "Finish time = ${t}"'
	cmdExceptRTypeExcutIndex3=$(( $cmdExceptRTypeExcutIndex3 + 1 ))
}

dealTestCase(){
for testFile in ${testPlans_file_array[@]}
do
	if [ ! -e $testFile ]
	then
		echo 测试文件$testFile不存在
		continue
	fi
	tempExcutT="#============test file: $testFile============"
	reallExcut

	num=1
	tempFold=${testFile##*/}

	while read cmdLine
	do
		tempExcutT='    '
		reallExcut
		tempExcutT='#echo ">>>>>>>>>>>>>>>>>>>>>>>>running test '$num'"'
		reallExcut

		cmdLineOrg=$cmdLine
		if [[ `expr index "$cmdLine" [` -eq 0 ]]
		then
			emptyLine=true
		fi
		cmdExcut[$cmdExcutParaP]="$basepath/source/$programName  > $basepath/outputs/t$num "

		cmdLine=${cmdLine}" -"

		while [[ ${#cmdLine} -gt 4 ]]
		do
			tempCmd1=

			tempCmd1=${cmdLine%%] *-*}
			parseCmd
			cmdLine=${cmdLine#*] *-}

			cmdLine="-"$cmdLine

			if [[ $cmdParameter == NULL ]] || [[ ${#cmdParameter} != 1 ]]
			then
				continue
			fi
			runallType
		done

		case $run_type in
			R) #echo 当前是R模式
			;;
			D) #echo 当前是D模式
				runTypeD_d D
			;;
			d) #echo 当前是d模式
				runTypeD_d d
			;;
			T) #echo 当前是T模式
				cmdT1=${programName%.*}
				cmdExceptRTypeExcut[$cmdExceptRTypeExcutIndex2]="cp \$ARISTOTLE_DB_DIR/$cmdT1.c.tr $basepath/traces/`expr $num - 1`.tr"
				cmdExceptRTypeExcutIndex2=$(( $cmdExceptRTypeExcutIndex2 + 1 ))
				unset cmdT1
			;;
			D_t) #echo 当前是D_t模式
			runTypeD_t_d_t D_t
			;;
			d_t) #echo 当前是d_t模式
			runTypeD_t_d_t d_t
			;;
			*) echo 该模式非法，脚本即将退出执行！
				exit
			;;
		esac


		if [[ $emptyLine == "false" ]]
		then
			excut
		fi
		reset		
		num=$(( $num + 1 ))
	done < $testFile
done
}


###########################################执行################################################

echo
echo 正在编译原版源代码...
makeSource 0
echo 原版源代码已编译完成
echo
echo '#!/bin/sh' > $runSHELL
echo 'export experiment_root='$experiment_root >> $runSHELL
echo 开始分析测试用例文件，请稍候...
dealTestCase
chmod +x $runSHELL
echo 测试用例文件已经分析完成
echo
echo 正在测试原版程序...
source $runSHELL
mkdir -p $basepath/outputs.alt/v$sourceCodeVersion
mv $basepath/outputs/* $basepath/outputs.alt/v$sourceCodeVersion
echo 原版程序测试已完成。对应输出文件见$basepath/outputs.alt/v$sourceCodeVersion/目录
echo
echo 正在创建FaultSeed源码包...
creatFaultSeed
echo FaultSeed源码包已创建完成

#########################################编译和测试错误版本程序##########################
seedVersion=1
while [[ $seedVersion -lt $seedVersionCount ]]
do
	echo
	echo 正在编译v${sourceCodeVersion}_FS_v$seedVersion目录下的已设置了错误的源代码...
	makeSource 1
	echo v${sourceCodeVersion}_FS_v$seedVersion目录下的已设置了错误的源代码已编译完成
#v${sourceCodeVersion}_FS_v$seedVersion和$sourceCodeDir始终是相等的
	echo
	echo 正在测试该已设置了错误的程序...
	source $runSHELL
	mkdir -p $basepath/outputs.alt/$sourceCodeDir
	mv $basepath/outputs/* $basepath/outputs.alt/$sourceCodeDir
	echo 该已设置了错误的程序测试已完成。对应输出文件见$basepath/outputs.alt/$sourceCodeDir/目录
	seedVersion=$(( $seedVersion + 1 ))
done
echo
echo 所有错误版本程序已测试完成
echo 
echo 正在比较测试结果并生成测试结果矩阵...
#####################################################################################

testCaseCounter=0
outFiNaAr=(" " " " " " " " " " " " " " " " " " " ")
outFiNaArSize=10
readonly outFiNaArSize
outFiNaArIndex=0
compOrNo=false

mkdir -p $basepath/result
testFileNa=${testPlansFile##*/}
mkdir -p $basepath/result/v$sourceCodeVersion
resultFile=$basepath/result/v$sourceCodeVersion/fault-matrix_$testFileNa
readonly resultFile

###############################比对本输出文件内容的函数#############################
comp(){
resultRoll=
seedVersion=1
#逐个版本进行比较
while [[ $seedVersion -lt $seedVersionCount ]]
do
	printf "#v$seedVersion\n" >> $basepath/scripts/compareFile
	tempVa=1
#对每个版本的每个输出文件进行比较
	for tempOutFiNa in ${outFiNaAr[@]}
	do
		if [[ x$tempOutFiNa == x" " ]]
		then
			continue
		fi
		if [ x$tempOutFiNa == x"export" ]
		then
			continue
		fi
		printf "cmp $basepath/outputs.alt/v$sourceCodeVersion/$tempOutFiNa $basepath/outputs.alt/v${sourceCodeVersion}_FS_v$seedVersion/$tempOutFiNa\n" >> $basepath/scripts/compareFile
		cmp -s $basepath/outputs.alt/v$sourceCodeVersion/$tempOutFiNa $basepath/outputs.alt/v${sourceCodeVersion}_FS_v$seedVersion/$tempOutFiNa
		retu=$?

		if [ $retu != 0 ] && [ $retu != 1 ]
		then
			retu=0
		fi
		tempVa=$(( $tempVa && $(( ! $retu )) ))
		retu=0
		if [ $tempVa -eq 0 ]
		then
			break
		fi
	done
	tempVa=$(( ! $tempVa ))
	resultRoll=${resultRoll}"$tempVa "
	seedVersion=$(( $seedVersion + 1 ))
done
#接下来清空文件名数组
outFiNaArIndex=0
while [[ $outFiNaArIndex -lt $outFiNaArSize ]]
do
	outFiNaAr[$outFiNaArIndex]=" "
	outFiNaArIndex=$(( $outFiNaArIndex + 1 ))
done
outFiNaArIndex=0
}
########################################################################
printf "#!/bin/sh\n" > $basepath/scripts/compareFile #准备比较命令的输出文件
while read testCaseLine
do
#输出提示信息，表示比较正在进行
	printf "-"
	if [[ -z $testCaseLine ]]
	then
		continue
	fi
	if [[ $testCaseLine == \#* ]]
	then
		if [[ $testCaseLine == "#echo "\"\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>\>running* ]]
		then

			testCaseCounter=$(( $testCaseCounter + 1 ))
			if [[ $testCaseCounter -eq 1 ]]
			then
				printf "" > $resultFile
			else
				printf "\n\n#test `expr $testCaseCounter - 1`\n" >> $basepath/scripts/compareFile
				comp
				printf "$resultRoll\n" >> $resultFile
				resultRoll=
			fi
			continue
		else
			continue
		fi
	fi
###############################提取输出文件名#############################
	outputFileName=${testCaseLine##*outputs/}
	outputFileName=${outputFileName%% *}
	if [[ -n $outputFileName ]]
	then
		outFiNaAr[$outFiNaArIndex]=$outputFileName
		outFiNaArIndex=$(( $outFiNaArIndex + 1 ))
	fi
		
########################################################################

done < $runSHELL
printf "\n\n#test $testCaseCounter\n" >> $basepath/scripts/compareFile
comp
printf "$resultRoll\n" >> $resultFile
resultRoll=

echo
echo 测试结果矩阵文件$resultFile已生成
echo

#######################################################################################
