import os
import subprocess
import threading
import time
import psutil


class Code_Checker:
    def set_io(
        self,
        code: str,
        language: str,
        input_data: str,
        expected_output: str,
        submission_id: int,
    ):
        # 把字符串全部写入文件
        extensions = {"Python": "py", "C/C++": "cpp", "Java": "java"}
        extension = extensions[language]
        self.code_path = f"code{submission_id}.{extension}"
        with open(self.code_path, "w") as f:
            f.write(code)

        self.language = language

        self.input_path = f"input{submission_id}.txt"
        with open(self.input_path, "w") as f:
            f.write(input_data + "\n")  # 末尾加换行符，防止不同语言的输入函数阻塞

        self.output_path = f"output{submission_id}.txt"
        self.output = expected_output

        self.error_path = f"error{submission_id}.txt"

        self.status = "P"
        self.info = ""
        return self

    def set_limit(self, time_limit: int, memory_limit: float):
        self.time_limit = time_limit
        self.memory_limit = int(memory_limit * 1024)
        self.used_time = 0  # ms
        self.used_memory = 0  # KB
        return self

    def test(self):
        """启动代码测试，返回参数：(status, info, used_time, used_memory)"""
        self.process = self.get_process()
        if self.process is None:
            return self.status, self.info, self.used_time, self.used_memory

        # 启动计时器
        timer = threading.Thread(target=self._timer_thread)
        timer.start()
        self.ptimer = psutil.Process(self.process.pid)
        self.start_time = time.perf_counter()

        # 等待进程结束
        self.process.wait()

        # 检查答案，输出结果
        self.check_answer()
        return self.status, self.info, self.used_time, self.used_memory

    def check_answer(self):
        """检查答案"""
        # 读取输出和错误信息
        with open(self.output_path, "r") as f:
            stdout = f.read()
        with open(self.error_path, "r") as f:
            stderr = f.read()

        if self.process.returncode != 0:
            if self.info == "":
                # 不是被计时器杀死，运行时出错
                self.status = "RE"
                self.info = f"Runtime Error: {stderr}"
        elif stdout.strip() == self.output.strip():
            # 运行成功，输出正确
            self.status = "AC"
            self.info = "Answer Accepted."
        else:
            # 运行成功，输出错误
            self.status = "WA"
            self.info = self._check_difference(self.output, stdout)
            print(self.output.strip(), stdout.strip(), self.info)

        # 删除临时文件
        os.remove(self.code_path)
        os.remove(self.input_path)
        os.remove(self.output_path)
        os.remove(self.error_path)
        if self.language == "C/C++":
            os.remove("test.exe")
        elif self.language == "Java":
            os.remove(self.code_path[:-5] + ".class")

    def get_process(self):
        """获取代码运行的进程"""
        if self.language == "Python":
            run_cmd = f"python {self.code_path} < {self.input_path} > {self.output_path} 2> {self.error_path}"
            return subprocess.Popen(run_cmd, shell=True)

        elif self.language == "C/C++":
            compile_cmd = f"g++ {self.code_path} -o test.exe 2> {self.error_path}"
            process = subprocess.Popen(compile_cmd, shell=True)
            process.wait()
            # 先检查编译是否成功
            if process.returncode != 0:
                self.status = "CE"
                with open(self.error_path, "r") as f:
                    stderr = f.read()
                self.info = f"Compile Error: {stderr}"
                return None
            run_cmd = (
                f"test < {self.input_path} > {self.output_path} 2> {self.error_path}"
            )
            return subprocess.Popen(run_cmd, shell=True)

    def _timer_thread(self):
        """计时器线程，当超时/超内存时杀死进程"""
        time.sleep(0.01)  # 等待进程启动
        while self.process.poll() is None:
            try:
                self.used_time = int((time.perf_counter() - self.start_time) * 1000)
                self.used_memory = max(
                    self.used_memory, self.ptimer.memory_info().rss // 1024
                )
                if self.used_time > self.time_limit:
                    self._terminate_testing()
                    self.status = "TLE"
                    self.info = "Time Limit Exceeded"
                    return
                if self.used_memory > self.memory_limit:
                    self._terminate_testing()
                    self.status = "MLE"
                    self.info = "Memory Limit Exceeded"
                    return
                time.sleep(0.001)  # 降低CPU占用
            except psutil.NoSuchProcess:
                return  # ignore

    def _terminate_testing(self):
        """终止测试"""
        parent = psutil.Process(self.process.pid)
        for child in parent.children(recursive=True):
            child.terminate()
        parent.terminate()

    @staticmethod
    def _check_difference(expected: str, actual: str):
        """比较预期输出和实际输出的不同，返回规范化字符串"""
        expected_lines = expected.split("\n")
        actual_lines = actual.split("\n")
        for i in range(min(len(expected_lines), len(actual_lines))):
            if expected_lines[i] == actual_lines[i]:
                continue
            for j in range(min(len(expected_lines[i]), len(actual_lines[i]))):
                if expected_lines[i][j] != actual_lines[i][j]:
                    return f"Line {i + 1} Column {j}: expected {expected_lines[i][j]}..., but got {actual_lines[i][j]}."
            if len(expected_lines[i]) > len(actual_lines[i]):
                return f"Line {i + 1} Column {j}: expected {expected_lines[i][j]}..., but got nothing"
            elif len(expected_lines[i]) < len(actual_lines[i]):
                return f"Line {i + 1} Column {j}: expected nothing, but got {actual_lines[i][j]}..."
        if len(expected_lines) > len(actual_lines):
            return f"Line {len(actual_lines) + 1}: expected a new line: {expected_lines[len(actual_lines)][0]}..., but got nothing"
        elif len(expected_lines) < len(actual_lines):
            return f"Line {len(expected_lines) + 1}: expected nothing, but got {actual_lines[len(expected_lines)][0]}..."
        else:
            return "Unknown difference"
