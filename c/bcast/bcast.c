#ifdef WIN32
# include <winsock2.h>
# include <io.h>
# define  socklen_t int
# define  sockopt_t char
#else
# include <netdb.h>
# include <netinet/in.h>
# include <arpa/inet.h>
# include <sys/time.h>
# include <sys/types.h>
# include <sys/socket.h>
# include <unistd.h>
# include <time.h>
# define  sockopt_t int
#endif

#define PORT 2080
 
int main(int argc, char *argv[])
{
	int sockfd;
	char buf[30];
	struct sockaddr_in sendaddr;
	struct sockaddr_in recvaddr;
	int numbytes;
	socklen_t addr_len;
	int broadcast=1;

	if ((sockfd = socket(PF_INET, SOCK_DGRAM, 0)) == -1) {
		perror("socket");
		exit(1);
	}
	if ((setsockopt(sockfd, SOL_SOCKET, SO_BROADCAST,
			&broadcast, sizeof broadcast)) == -1) {
		perror("setsockopt - SO_SOCKET ");
		exit(1);
	}
	printf("Socket created\n");

	memset(&sendaddr, 0, sizeof sendaddr);
	sendaddr.sin_family = AF_INET;
	sendaddr.sin_port = htons(PORT);
	sendaddr.sin_addr.s_addr = INADDR_BROADCAST;

	if (argc > 1 && argv[1][0] == '-') { /* Broadcast as client */
		time_t now = time(NULL);
		numbytes = sendto(sockfd, ctime(&now), 24, 0,
				(struct sockaddr *)&sendaddr, sizeof sendaddr);
		printf("Broadcasted a packet: '%.*s'\n", 24, ctime(&now));
		exit(0);
	}

	memset(&recvaddr, 0, sizeof recvaddr);
	recvaddr.sin_family = AF_INET;
	recvaddr.sin_port = htons(PORT);
	recvaddr.sin_addr.s_addr = argc > 1 ? inet_addr(argv[1]) : INADDR_ANY;
	if (bind(sockfd, (struct sockaddr*)&recvaddr, sizeof recvaddr) == -1) {
		perror("bind");
		exit(1);
	}
	numbytes = sendto(sockfd, "Hello", 5 , 0,
			(struct sockaddr *)&sendaddr, sizeof sendaddr);

	for (;;) {
		int n;
		fd_set set;
		struct timeval time_500ms = { 0, 500*1000 };
		FD_ZERO(&set);
		FD_SET(sockfd, &set);

		n = select(sockfd+1, &set, NULL, NULL, &time_500ms);
		if (n < 0) {
			perror("select");
			break;
		}
		else if (n == 0) {
			printf("sleep(5)\n");
			sleep(5);
		}
		else if (!FD_ISSET(sockfd, &set)) {
			perror("FD_ISSET");
			break;
		}
		else {
			addr_len = sizeof sendaddr;
			if ((numbytes = recvfrom(sockfd, buf, sizeof buf, 0,
						(struct sockaddr *)&sendaddr, &addr_len)) > 0)
			{
				time_t now = time(NULL);
				printf("recvfrom: '%.*s' at %s\n", numbytes, buf, ctime(&now));
			}
			else
				perror("recvfrom");
		}
	}
	close(sockfd); 
	return 0;
}
