package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"time"
)

type Snapshot struct {
	Type   string      `json:"type"`
	Ts     int64       `json:"ts"`
	CPU    CPU         `json:"cpu"`
	Memory Memory      `json:"memory"`
	Disks  []Disk      `json:"disks"`
	Net    []Net       `json:"net"`
	GPUs   []NvidiaGPU `json:"gpus"`
}

type CPU struct {
	Total float64 `json:"total"`
	Cores int     `json:"cores"`
}

type Memory struct {
	Used  uint64 `json:"used"`
	Total uint64 `json:"total"`
}

type Disk struct {
	Name  string `json:"name"`
	Mount string `json:"mount"`
	Used  uint64 `json:"used"`
	Total uint64 `json:"total"`
}

type Net struct {
	Name string `json:"name"`
	Rx   uint64 `json:"rx"`
	Tx   uint64 `json:"tx"`
}

type NvidiaGPU struct {
	Index    int     `json:"index"`
	Name     string  `json:"name"`
	Util     float64 `json:"util"`
	MemUsed  uint64  `json:"memUsed"`
	MemTotal uint64  `json:"memTotal"`
}

func main() {
	for {
		s := Snapshot{
			Type: "metrics",
			Ts:   time.Now().Unix(),
			CPU: CPU{
				Total: 0,
				Cores: runtime.NumCPU(),
			},
			Memory: Memory{},
			Disks:  []Disk{},
			Net:    []Net{},
			GPUs:   nvidia(),
		}
		data, _ := json.Marshal(s)
		fmt.Println(string(data))
		time.Sleep(2 * time.Second)
	}
}

func nvidia() []NvidiaGPU {
	cmd := exec.Command("nvidia-smi", "--query-gpu=index,name,utilization.gpu,memory.used,memory.total", "--format=csv,noheader,nounits")
	out, err := cmd.Output()
	if err != nil {
		return []NvidiaGPU{}
	}
	rows := strings.Split(strings.TrimSpace(string(out)), "\n")
	gpus := make([]NvidiaGPU, 0, len(rows))
	for _, row := range rows {
		parts := strings.Split(row, ",")
		if len(parts) < 5 {
			continue
		}
		index, _ := strconv.Atoi(strings.TrimSpace(parts[0]))
		util, _ := strconv.ParseFloat(strings.TrimSpace(parts[2]), 64)
		used, _ := strconv.ParseUint(strings.TrimSpace(parts[3]), 10, 64)
		total, _ := strconv.ParseUint(strings.TrimSpace(parts[4]), 10, 64)
		gpus = append(gpus, NvidiaGPU{
			Index:    index,
			Name:     strings.TrimSpace(parts[1]),
			Util:     util,
			MemUsed:  used,
			MemTotal: total,
		})
	}
	return gpus
}
