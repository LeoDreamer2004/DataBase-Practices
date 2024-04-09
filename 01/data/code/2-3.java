import java.util.Scanner;
public class Main {
    public static void main(String[] args) {
        int k, n = 2;
        double s = 1;
        Scanner sc = new Scanner(System.in);
        k = sc.nextInt();
        for (; s <= k; n++) {
            s += 1.0 / n;
        }
        System.out.println(n-1);
    }
}